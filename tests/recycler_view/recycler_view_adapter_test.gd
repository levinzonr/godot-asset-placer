extends GdUnitTestSuite

# gdUnit's abstract assertion signatures hide the asynchronous error-capture implementation.
@warning_ignore_start("redundant_await")

const Adapter = preload(
	"res://addons/asset_placer/ui/components/recycler_view/recycler_view_adapter.gd"
)
const Holder = preload(
	"res://addons/asset_placer/ui/components/recycler_view/recycler_view_holder.gd"
)

var _adapter: TrackingAdapter
var _parent: Control
var _holder: Holder
var _item_view: ItemView


class ItemView:
	extends Control

	var ready_calls: int = 0
	var on_enter: Callable

	@onready var button: Button = get_node("Button")

	func _init() -> void:
		var child := Button.new()
		child.name = "Button"
		child.toggle_mode = true
		add_child(child)

	func _enter_tree() -> void:
		if on_enter.is_valid():
			on_enter.call()

	func _ready() -> void:
		ready_calls += 1


class TrackingAdapter:
	extends Adapter

	var items: Array[String] = ["First", "Second"]
	var creation_parent: Control
	var creation_calls: int = 0
	var bound_positions: Array[int] = []
	var positions_seen_in_bind: Array[int] = []
	var positions_seen_in_recycle: Array[int] = []
	var clicked_positions: Array[int] = []

	func get_item_count() -> int:
		return items.size()

	func _create_view_holder(parent: Control) -> Holder:
		creation_parent = parent
		creation_calls += 1
		var item := ItemView.new()
		var holder := Holder.new(item)
		var button: Button = item.get_node("Button")
		button.pressed.connect(
			func(): clicked_positions.append(holder.get_binding_adapter_position())
		)
		return holder

	func _bind_view_holder(holder: Holder, position: int) -> void:
		bound_positions.append(position)
		positions_seen_in_bind.append(holder.get_binding_adapter_position())
		var item: ItemView = holder.get_item_view()
		item.button.text = items[position]
		item.button.set_pressed_no_signal(false)

	func _on_view_recycled(holder: Holder) -> void:
		positions_seen_in_recycle.append(holder.get_binding_adapter_position())
		var item: ItemView = holder.get_item_view()
		item.button.text = ""
		item.button.set_pressed_no_signal(false)


class FactoryAdapter:
	extends Adapter

	var result: Holder

	func _create_view_holder(_parent: Control) -> Holder:
		return result


class PlainAdapter:
	extends Adapter

	func get_item_count() -> int:
		return 1

	func _create_view_holder(_parent: Control) -> Holder:
		return Holder.new(Control.new())

	func _bind_view_holder(_holder: Holder, _position: int) -> void:
		pass


func before_test() -> void:
	_adapter = TrackingAdapter.new()
	_parent = Control.new()
	add_child(_parent)
	_holder = _adapter.create_view_holder(_parent)
	_item_view = _holder.get_item_view()


func after_test() -> void:
	if is_instance_valid(_item_view):
		_item_view.free()
	if is_instance_valid(_parent):
		_parent.free()


func test_creation_passes_parent_context_without_mounting_or_binding() -> void:
	assert_object(_adapter.creation_parent).is_same(_parent)
	assert_int(_adapter.creation_calls).is_equal(1)
	assert_object(_item_view.get_parent()).is_null()
	assert_bool(_item_view.is_inside_tree()).is_false()
	assert_bool(_item_view.is_node_ready()).is_false()
	assert_bool(_holder.is_bound()).is_false()
	assert_array(_adapter.bound_positions).is_empty()
	assert_int(_adapter.get_item_count()).is_equal(2)


func test_binding_sets_position_before_the_hook_and_uses_ready_children() -> void:
	_parent.add_child(_item_view)
	assert_bool(_adapter.bind_view_holder(_holder, 1)).is_true()
	assert_bool(_holder.is_bound()).is_true()
	assert_int(_holder.get_binding_adapter_position()).is_equal(1)
	assert_array(_adapter.bound_positions).contains_exactly([1])
	assert_array(_adapter.positions_seen_in_bind).contains_exactly([1])
	assert_str(_item_view.button.text).is_equal("Second")
	assert_int(_item_view.ready_calls).is_equal(1)


func test_rebinding_the_same_position_uses_current_data_and_resets_ui_state() -> void:
	_parent.add_child(_item_view)
	_adapter.bind_view_holder(_holder, 0)
	_item_view.button.set_pressed_no_signal(true)
	_adapter.items[0] = "Updated"
	assert_bool(_adapter.bind_view_holder(_holder, 0)).is_true()
	assert_str(_item_view.button.text).is_equal("Updated")
	assert_bool(_item_view.button.button_pressed).is_false()
	assert_array(_adapter.bound_positions).contains_exactly([0, 0])
	assert_int(_adapter.creation_calls).is_equal(1)
	assert_int(_item_view.ready_calls).is_equal(1)


func test_one_signal_connection_observes_the_current_binding() -> void:
	_parent.add_child(_item_view)
	_adapter.bind_view_holder(_holder, 0)
	_item_view.button.pressed.emit()
	_adapter.bind_view_holder(_holder, 1)
	_item_view.button.pressed.emit()
	_adapter.bind_view_holder(_holder, 1)
	_item_view.button.pressed.emit()
	assert_array(_adapter.clicked_positions).contains_exactly([0, 1, 1])


func test_recycling_invalidates_before_cleanup_without_changing_node_lifetime() -> void:
	_parent.add_child(_item_view)
	_adapter.bind_view_holder(_holder, 1)
	_adapter.recycle_view_holder(_holder)
	assert_bool(_holder.is_bound()).is_false()
	assert_int(_holder.get_binding_adapter_position()).is_equal(Holder.NO_POSITION)
	assert_array(_adapter.positions_seen_in_recycle).contains_exactly([Holder.NO_POSITION])
	assert_str(_item_view.button.text).is_empty()
	assert_object(_item_view.get_parent()).is_same(_parent)
	assert_bool(_item_view.visible).is_true()
	assert_bool(_item_view.is_queued_for_deletion()).is_false()


func test_recycling_is_idempotent_and_the_holder_can_be_rebound() -> void:
	_adapter.recycle_view_holder(_holder)
	assert_array(_adapter.positions_seen_in_recycle).is_empty()
	_parent.add_child(_item_view)
	_adapter.bind_view_holder(_holder, 0)
	_adapter.recycle_view_holder(_holder)
	_adapter.recycle_view_holder(_holder)
	assert_array(_adapter.positions_seen_in_recycle).contains_exactly([Holder.NO_POSITION])
	assert_bool(_adapter.bind_view_holder(_holder, 1)).is_true()
	assert_str(_item_view.button.text).is_equal("Second")
	assert_int(_holder.get_binding_adapter_position()).is_equal(1)
	assert_int(_adapter.creation_calls).is_equal(1)


func test_binding_before_mounting_is_rejected() -> void:
	await (
		assert_error(func(): assert_bool(_adapter.bind_view_holder(_holder, 0)).is_false())
		. is_push_error(
			"RecyclerViewAdapter.bind_view_holder() requires a mounted, ready item view."
		)
	)
	assert_bool(_holder.is_bound()).is_false()
	assert_array(_adapter.bound_positions).is_empty()


func test_binding_during_tree_entry_is_rejected_until_ready() -> void:
	_item_view.on_enter = func(): assert_bool(_adapter.bind_view_holder(_holder, 0)).is_false()
	await (
		assert_error(func(): _parent.add_child(_item_view))
		. is_push_error(
			"RecyclerViewAdapter.bind_view_holder() requires a mounted, ready item view."
		)
	)
	_item_view.on_enter = Callable()
	assert_bool(_holder.is_bound()).is_false()
	assert_array(_adapter.bound_positions).is_empty()
	assert_bool(_adapter.bind_view_holder(_holder, 0)).is_true()


func test_detached_ready_views_cannot_bind_until_remounted() -> void:
	_parent.add_child(_item_view)
	_adapter.bind_view_holder(_holder, 0)
	_parent.remove_child(_item_view)
	await (
		assert_error(func(): assert_bool(_adapter.bind_view_holder(_holder, 1)).is_false())
		. is_push_error(
			"RecyclerViewAdapter.bind_view_holder() requires a mounted, ready item view."
		)
	)
	assert_int(_holder.get_binding_adapter_position()).is_equal(0)
	_parent.add_child(_item_view)
	assert_bool(_adapter.bind_view_holder(_holder, 1)).is_true()
	assert_int(_item_view.ready_calls).is_equal(1)


func test_invalid_positions_and_a_shrunk_dataset_preserve_the_previous_binding() -> void:
	_parent.add_child(_item_view)
	_adapter.bind_view_holder(_holder, 1)
	for position in [-1, 2, 100]:
		await (
			assert_error(
				func(): assert_bool(_adapter.bind_view_holder(_holder, position)).is_false()
			)
			. is_push_error(
				"RecyclerViewAdapter.bind_view_holder() position is outside the current item count."
			)
		)
	_adapter.items.clear()
	await (
		assert_error(func(): assert_bool(_adapter.bind_view_holder(_holder, 0)).is_false())
		. is_push_error(
			"RecyclerViewAdapter.bind_view_holder() position is outside the current item count."
		)
	)
	assert_int(_holder.get_binding_adapter_position()).is_equal(1)
	assert_array(_adapter.bound_positions).contains_exactly([1])


func test_data_change_notification_is_synchronous_and_does_not_rebind() -> void:
	_parent.add_child(_item_view)
	_adapter.bind_view_holder(_holder, 0)
	var observed_counts: Array[int] = []
	_adapter.data_set_changed.connect(func(): observed_counts.append(_adapter.get_item_count()))
	_adapter.items.append("Third")
	_adapter.notify_data_set_changed()
	_adapter.notify_data_set_changed()
	assert_array(observed_counts).contains_exactly([3, 3])
	assert_array(_adapter.bound_positions).contains_exactly([0])
	assert_int(_holder.get_binding_adapter_position()).is_equal(0)


func test_invalid_holder_or_freed_view_cannot_bind() -> void:
	await (
		assert_error(func(): assert_bool(_adapter.bind_view_holder(null, 0)).is_false())
		. is_push_error("RecyclerViewAdapter requires a holder with a live item view.")
	)
	_item_view.free()
	await (
		assert_error(func(): assert_bool(_adapter.bind_view_holder(_holder, 0)).is_false())
		. is_push_error("RecyclerViewAdapter requires a holder with a live item view.")
	)
	assert_bool(_holder.is_bound()).is_false()
	assert_array(_adapter.bound_positions).is_empty()


func test_views_queued_for_deletion_cannot_bind() -> void:
	_parent.add_child(_item_view)
	_item_view.queue_free()
	await (
		assert_error(func(): assert_bool(_adapter.bind_view_holder(_holder, 0)).is_false())
		. is_push_error("RecyclerViewAdapter cannot use an item view queued for deletion.")
	)
	assert_array(_adapter.bound_positions).is_empty()


func test_creation_requires_a_live_parent() -> void:
	await (
		assert_error(func(): assert_object(_adapter.create_view_holder(null)).is_null())
		. is_push_error("RecyclerViewAdapter.create_view_holder() requires a live parent.")
	)
	var deleted_parent := Control.new()
	deleted_parent.free()
	await (
		assert_error(func(): assert_object(_adapter.create_view_holder(deleted_parent)).is_null())
		. is_push_error("RecyclerViewAdapter.create_view_holder() requires a live parent.")
	)
	assert_int(_adapter.creation_calls).is_equal(1)


func test_factory_result_must_have_a_live_unattached_unbound_view() -> void:
	var factory := FactoryAdapter.new()
	for result in [null, Holder.new(null)]:
		factory.result = result
		await (
			assert_error(func(): assert_object(factory.create_view_holder(_parent)).is_null())
			. is_push_error("RecyclerViewAdapter requires a holder with a live item view.")
		)
	factory.result = _holder
	_parent.add_child(_item_view)
	await (
		assert_error(func(): assert_object(factory.create_view_holder(_parent)).is_null())
		. is_push_error(
			"RecyclerViewAdapter._create_view_holder() must return an unattached, unbound holder."
		)
	)
	_adapter.bind_view_holder(_holder, 0)
	_parent.remove_child(_item_view)
	await (
		assert_error(func(): assert_object(factory.create_view_holder(_parent)).is_null())
		. is_push_error(
			"RecyclerViewAdapter._create_view_holder() must return an unattached, unbound holder."
		)
	)
	assert_bool(is_instance_valid(_item_view)).is_true()
	assert_bool(_item_view.is_queued_for_deletion()).is_false()


func test_recycling_hook_is_optional() -> void:
	var adapter := PlainAdapter.new()
	var holder := adapter.create_view_holder(_parent)
	var view := holder.get_item_view()
	_parent.add_child(view)
	assert_bool(adapter.bind_view_holder(holder, 0)).is_true()
	adapter.recycle_view_holder(holder)
	assert_bool(holder.is_bound()).is_false()
	assert_object(view.get_parent()).is_same(_parent)
