extends GdUnitTestSuite

const Recycler = preload("res://addons/asset_placer/ui/components/recycler_view/recycler_view.gd")
const Adapter = preload(
	"res://addons/asset_placer/ui/components/recycler_view/recycler_view_adapter.gd"
)
const Holder = preload(
	"res://addons/asset_placer/ui/components/recycler_view/recycler_view_holder.gd"
)
const GridLayout = preload(
	"res://addons/asset_placer/ui/components/recycler_view/grid_layout_manager.gd"
)
const INITIAL_SIZE: Vector2 = Vector2(320.0, 200.0)
const SETTLE_FRAMES: int = 8
const EPSILON: float = 0.01

var _recycler: Recycler
var _adapter: TrackingAdapter
var _layout: GridLayout
var _adapters: Array[TrackingAdapter] = []


class ItemView:
	extends Control

	var ready_calls: int = 0

	@onready var button: Button = get_node("Button")

	func _init() -> void:
		var child: Button = Button.new()
		child.name = "Button"
		add_child(child)

	func _ready() -> void:
		ready_calls += 1


class TrackingAdapter:
	extends Adapter

	var item_count: int = 10000
	var revision: int = 0
	var create_calls: int = 0
	var bound_positions: Array[int] = []
	var positions_seen_in_bind: Array[int] = []
	var positions_seen_in_recycle: Array[int] = []
	var ready_when_bound: Array[bool] = []
	var roots: Array[ItemView] = []
	var holders: Array[Holder] = []
	var bind_counts_by_root: Dictionary = {}
	var on_create: Callable

	func get_item_count() -> int:
		return item_count

	func _create_view_holder(_parent: Control) -> Holder:
		create_calls += 1
		var view: ItemView = ItemView.new()
		var holder: Holder = Holder.new(view)
		roots.append(view)
		holders.append(holder)
		if on_create.is_valid():
			on_create.call()
		return holder

	func _bind_view_holder(holder: Holder, position: int) -> void:
		var view: ItemView = holder.get_item_view()
		bound_positions.append(position)
		positions_seen_in_bind.append(holder.get_binding_adapter_position())
		ready_when_bound.append(
			view.is_inside_tree() and view.is_node_ready() and view.button != null
		)
		var previous_count: int = bind_counts_by_root.get(view.get_instance_id(), 0)
		bind_counts_by_root[view.get_instance_id()] = previous_count + 1
		if view.button != null:
			view.button.text = "%d:%d" % [revision, position]

	func _on_view_recycled(holder: Holder) -> void:
		positions_seen_in_recycle.append(holder.get_binding_adapter_position())
		var view: ItemView = holder.get_item_view()
		if view.button != null:
			view.button.text = ""


func before_test() -> void:
	_adapter = TrackingAdapter.new()
	_adapters = [_adapter]
	_layout = GridLayout.new()
	_layout.span_count = 3
	_layout.item_height = 100.0
	_layout.spacing = Vector2(10.0, 8.0)
	_recycler = Recycler.new()
	_recycler.size = INITIAL_SIZE
	_recycler.adapter = _adapter
	_recycler.layout_manager = _layout


func after_test() -> void:
	if is_instance_valid(_recycler):
		_recycler.free()
	await _settle()
	for adapter in _adapters:
		for view in adapter.roots:
			assert_bool(is_instance_valid(view)).is_false()
			if is_instance_valid(view):
				view.free()
	_adapters.clear()


func test_off_tree_configuration_mounts_ready_views_in_a_plain_content_control() -> void:
	_recycler.request_layout()
	_adapter.notify_data_set_changed()
	await _settle()
	assert_bool(_recycler.is_inside_tree()).is_false()
	assert_int(_adapter.create_calls).is_zero()
	assert_int(_recycler.get_active_view_holder_count()).is_zero()
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	assert_int(_recycler.recycled_pool_capacity).is_equal(12)
	await _mount()

	assert_int(_recycler.vertical_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_SHOW_ALWAYS)
	assert_int(_recycler.horizontal_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_DISABLED)
	var panel: StyleBox = _recycler.get_theme_stylebox("panel")
	assert_vector(panel.get_minimum_size()).is_equal(Vector2.ZERO)
	var bar: VScrollBar = _recycler.get_v_scroll_bar()
	assert_bool(bar.is_visible_in_tree()).is_true()
	_assert_vector_approx(
		_recycler.get_layout_viewport_size(), Vector2(_recycler.size.x - bar.size.x, bar.page)
	)
	assert_float(bar.page).is_equal_approx(_recycler.size.y, EPSILON)
	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i(0, 6))
	_assert_applied_layout()
	_assert_live_inventory(_adapter)
	for ready_state in _adapter.ready_when_bound:
		assert_bool(ready_state).is_true()
	assert_array(_adapter.positions_seen_in_bind).contains_exactly(_adapter.bound_positions)


func test_ten_thousand_items_only_create_the_applied_visible_range() -> void:
	await _mount()
	_assert_applied_layout()
	var applied: Vector2i = _recycler.get_visible_range()
	var visible_count: int = applied.y - applied.x
	assert_int(_adapter.item_count).is_equal(10000)
	assert_int(visible_count).is_equal(6)
	assert_int(_adapter.create_calls).is_equal(visible_count)
	assert_int(_adapter.bound_positions.size()).is_equal(visible_count)
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	assert_float(_recycler.get_content_size().y).is_equal_approx(360064.0, EPSILON)
	assert_object(_recycler.find_view_holder_for_adapter_position(9999)).is_null()
	_assert_live_inventory(_adapter)
	var bind_calls: int = _adapter.bound_positions.size()
	await _settle()
	assert_int(_adapter.create_calls).is_equal(visible_count)
	assert_int(_adapter.bound_positions.size()).is_equal(bind_calls)


func test_scrolling_reuses_outgoing_views_without_rebinding_retained_holders() -> void:
	await _mount()
	var retained: Array[Holder] = []
	var retained_bind_counts: Array[int] = []
	for position in range(3, 6):
		var holder: Holder = _recycler.find_view_holder_for_adapter_position(position)
		retained.append(holder)
		var bind_count: int = _adapter.bind_counts_by_root.get(
			holder.get_item_view().get_instance_id(), 0
		)
		retained_bind_counts.append(bind_count)
	var outgoing_roots: Array[Control] = []
	for position in range(3):
		var holder: Holder = _recycler.find_view_holder_for_adapter_position(position)
		outgoing_roots.append(holder.get_item_view())
	var create_calls: int = _adapter.create_calls
	var bind_calls: int = _adapter.bound_positions.size()
	_recycler.scroll_vertical = 108
	await _settle()

	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i(3, 9))
	assert_int(_adapter.create_calls).is_equal(create_calls)
	assert_array(_adapter.bound_positions.slice(bind_calls)).contains_exactly_in_any_order(
		[6, 7, 8]
	)
	for index in range(retained.size()):
		var holder: Holder = _recycler.find_view_holder_for_adapter_position(index + 3)
		assert_object(holder).is_same(retained[index])
		var bind_count: int = _adapter.bind_counts_by_root.get(
			holder.get_item_view().get_instance_id(), 0
		)
		assert_int(bind_count).is_equal(retained_bind_counts[index])
	for position in range(6, 9):
		var holder: Holder = _recycler.find_view_holder_for_adapter_position(position)
		assert_bool(outgoing_roots.has(holder.get_item_view())).is_true()
	assert_int(_adapter.positions_seen_in_recycle.size()).is_equal(3)
	_assert_applied_layout()
	_assert_live_inventory(_adapter)


func test_large_scroll_jump_binds_only_the_destination_and_reuses_views() -> void:
	await _mount()
	var create_calls: int = _adapter.create_calls
	var bind_calls: int = _adapter.bound_positions.size()
	_recycler.scroll_vertical = 108000
	await _settle()

	assert_int(_recycler.scroll_vertical).is_equal(108000)
	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i(3000, 3006))
	assert_array(_adapter.bound_positions.slice(bind_calls)).contains_exactly_in_any_order(
		[3000, 3001, 3002, 3003, 3004, 3005]
	)
	assert_int(_adapter.create_calls).is_equal(create_calls)
	assert_int(_adapter.positions_seen_in_recycle.size()).is_equal(6)
	assert_object(_recycler.find_view_holder_for_adapter_position(0)).is_null()
	_assert_applied_layout()
	_assert_live_inventory(_adapter)


func test_viewport_resize_updates_cell_widths_without_rebinding_retained_items() -> void:
	await _mount()
	var holder: Holder = _recycler.find_view_holder_for_adapter_position(2)
	var old_width: float = holder.get_item_view().size.x
	var bind_calls: int = _adapter.bound_positions.size()
	_recycler.size = Vector2(620.0, 200.0)
	await _settle()

	assert_object(_recycler.find_view_holder_for_adapter_position(2)).is_same(holder)
	assert_float(holder.get_item_view().size.x).is_equal_approx(old_width + 100.0, EPSILON)
	assert_float(_recycler.get_layout_viewport_size().x).is_equal_approx(
		_recycler.size.x - _recycler.get_v_scroll_bar().size.x, EPSILON
	)
	assert_int(_adapter.bound_positions.size()).is_equal(bind_calls)
	_assert_applied_layout()


func test_themed_scrollbar_width_is_excluded_from_native_layout_area() -> void:
	var theme: Theme = Theme.new()
	var scroll_style: StyleBoxEmpty = StyleBoxEmpty.new()
	scroll_style.content_margin_left = 37.0
	var grabber_style: StyleBoxEmpty = StyleBoxEmpty.new()
	grabber_style.content_margin_left = 37.0
	theme.set_stylebox("scroll", "VScrollBar", scroll_style)
	for style_name in ["grabber", "grabber_highlight", "grabber_pressed"]:
		theme.set_stylebox(style_name, "VScrollBar", grabber_style)
	_recycler.theme = theme
	await _mount()

	var bar: VScrollBar = _recycler.get_v_scroll_bar()
	assert_float(bar.size.x).is_greater_equal(37.0)
	_assert_vector_approx(
		_recycler.get_layout_viewport_size(), Vector2(_recycler.size.x - bar.size.x, bar.page)
	)
	var last_column: Holder = _recycler.find_view_holder_for_adapter_position(2)
	var view: Control = last_column.get_item_view()
	assert_float(view.position.x + view.size.x).is_equal_approx(
		_recycler.get_layout_viewport_size().x, EPSILON
	)
	_assert_applied_layout()


func test_request_layout_applies_manual_layout_manager_configuration_changes() -> void:
	await _mount()
	_layout.span_count = 2
	_layout.item_height = 50.25
	_layout.spacing = Vector2(20.0, 5.0)
	_recycler.request_layout()
	_recycler.request_layout()
	_recycler.request_layout()
	await _settle()

	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i(0, 8))
	assert_float(_recycler.get_content_size().y).is_equal_approx(276245.0, EPSILON)
	_assert_applied_layout()
	_assert_live_inventory(_adapter)

	var bar: VScrollBar = _recycler.get_v_scroll_bar()
	bar.step = 0.0
	bar.value = 76.5
	await _settle()
	assert_float(bar.value).is_equal_approx(76.5, EPSILON)
	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i(2, 12))
	_assert_applied_layout()


func test_pool_capacity_hides_parented_views_and_evicts_excess_after_shrinking() -> void:
	_recycler.recycled_pool_capacity = 2
	_recycler.size = Vector2(320.0, 640.0)
	await _mount()
	var original_count: int = _recycler.get_active_view_holder_count()
	assert_int(original_count).is_equal(18)
	var original_roots: Array[ItemView] = _adapter.roots.duplicate()
	_recycler.size = INITIAL_SIZE
	await _settle()

	assert_int(_recycler.get_active_view_holder_count()).is_equal(6)
	assert_int(_recycler.get_recycled_view_holder_count()).is_equal(2)
	assert_int(_adapter.positions_seen_in_recycle.size()).is_equal(original_count - 6)
	var freed_count: int = 0
	for view in original_roots:
		if not is_instance_valid(view):
			freed_count += 1
	assert_int(freed_count).is_equal(original_count - 8)
	_assert_live_inventory(_adapter)

	var create_calls: int = _adapter.create_calls
	_recycler.size = Vector2(320.0, 308.0)
	await _settle()
	assert_int(_recycler.get_active_view_holder_count()).is_equal(9)
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	assert_int(_adapter.create_calls).is_equal(create_calls + 1)
	_assert_applied_layout()
	_assert_live_inventory(_adapter)


func test_zero_capacity_still_reuses_outgoing_holders_then_frees_unused_views() -> void:
	_recycler.recycled_pool_capacity = -5
	assert_int(_recycler.recycled_pool_capacity).is_zero()
	await _mount()
	var create_calls: int = _adapter.create_calls
	_recycler.scroll_vertical = 108
	await _settle()
	assert_int(_adapter.create_calls).is_equal(create_calls)
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	_assert_applied_layout()

	_recycler.scroll_vertical = 0
	await _settle()
	var outgoing_roots: Array[Control] = []
	for position in range(3, 6):
		var holder: Holder = _recycler.find_view_holder_for_adapter_position(position)
		outgoing_roots.append(holder.get_item_view())
	_recycler.size = Vector2(320.0, 100.0)
	await _settle()
	assert_int(_recycler.get_active_view_holder_count()).is_equal(3)
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	for view in outgoing_roots:
		assert_bool(is_instance_valid(view)).is_false()
	_assert_applied_layout()
	_assert_live_inventory(_adapter)


func test_missing_adapter_or_layout_is_empty_and_can_be_configured_later() -> void:
	_recycler.adapter = null
	_recycler.layout_manager = null
	await _mount()
	_assert_empty_layout()
	assert_int(_adapter.create_calls).is_zero()
	_recycler.adapter = _adapter
	await _settle()
	_assert_empty_layout()
	assert_int(_adapter.create_calls).is_zero()
	_recycler.layout_manager = _layout
	await _settle()
	_assert_applied_layout()

	_recycler.adapter = null
	await _settle()
	_assert_empty_layout()
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	_recycler.adapter = _adapter
	await _settle()
	_assert_applied_layout()
	_recycler.layout_manager = null
	await _settle()
	_assert_empty_layout()
	_recycler.layout_manager = _layout
	await _settle()
	_assert_applied_layout()
	_assert_live_inventory(_adapter)


func test_empty_dataset_can_populate_and_become_empty_again() -> void:
	_adapter.item_count = 0
	await _mount()
	_assert_empty_layout()
	assert_int(_adapter.create_calls).is_zero()
	_adapter.item_count = 4
	_adapter.notify_data_set_changed()
	await _settle()
	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i(0, 4))
	assert_int(_adapter.create_calls).is_equal(4)
	_assert_applied_layout()

	_adapter.item_count = 0
	_adapter.notify_data_set_changed()
	await _settle()
	_assert_empty_layout()
	assert_int(_recycler.scroll_vertical).is_zero()
	assert_int(_recycler.get_recycled_view_holder_count()).is_equal(4)
	_assert_live_inventory(_adapter)


func test_repeated_notifications_coalesce_into_one_rebind_with_latest_data() -> void:
	await _mount()
	var bind_calls: int = _adapter.bound_positions.size()
	var create_calls: int = _adapter.create_calls
	var original_holders: Array[Holder] = []
	for position in range(6):
		original_holders.append(_recycler.find_view_holder_for_adapter_position(position))
	for revision in range(1, 4):
		_adapter.revision = revision
		_adapter.notify_data_set_changed()
		_recycler.request_layout()
	assert_int(_adapter.bound_positions.size()).is_equal(bind_calls)
	await _settle()

	assert_array(_adapter.bound_positions.slice(bind_calls)).contains_exactly_in_any_order(
		[0, 1, 2, 3, 4, 5]
	)
	assert_int(_adapter.create_calls).is_equal(create_calls)
	for position in range(6):
		var holder: Holder = _recycler.find_view_holder_for_adapter_position(position)
		assert_object(holder).is_same(original_holders[position])
		var view: ItemView = holder.get_item_view()
		assert_str(view.button.text).is_equal("3:%d" % position)
	_assert_applied_layout()


func test_data_shrink_waits_for_native_scroll_clamp_before_binding_new_positions() -> void:
	await _mount()
	_recycler.scroll_vertical = 108000
	await _settle()
	assert_int(_recycler.scroll_vertical).is_equal(108000)
	var bind_calls: int = _adapter.bound_positions.size()
	_adapter.item_count = 10
	_adapter.notify_data_set_changed()
	await _settle()

	var bar: VScrollBar = _recycler.get_v_scroll_bar()
	var native_maximum: float = maxf(0.0, bar.max_value - bar.page)
	assert_float(float(_recycler.scroll_vertical)).is_equal_approx(native_maximum, 1.0)
	assert_int(_recycler.scroll_vertical).is_greater(0)
	assert_float(bar.max_value).is_equal_approx(_recycler.get_content_size().y, EPSILON)
	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i(6, 10))
	assert_array(_adapter.bound_positions.slice(bind_calls)).contains_exactly_in_any_order(
		[6, 7, 8, 9]
	)
	_assert_applied_layout()
	_assert_live_inventory(_adapter)


func test_adapter_replacement_frees_old_active_and_pooled_views_and_disconnects_signal() -> void:
	_recycler.size = Vector2(320.0, 640.0)
	await _mount()
	_recycler.size = INITIAL_SIZE
	await _settle()
	assert_int(_recycler.get_recycled_view_holder_count()).is_greater(0)
	var old_adapter: TrackingAdapter = _adapter
	var old_roots: Array[ItemView] = old_adapter.roots.duplicate()
	assert_int(old_adapter.data_set_changed.get_connections().size()).is_equal(1)
	_adapter = TrackingAdapter.new()
	_adapter.item_count = 4
	_adapter.revision = 7
	_adapters.append(_adapter)
	_recycler.adapter = _adapter
	await _settle()

	assert_int(old_adapter.data_set_changed.get_connections().size()).is_zero()
	for view in old_roots:
		assert_bool(is_instance_valid(view)).is_false()
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	assert_int(_adapter.create_calls).is_equal(4)
	_assert_applied_layout()
	_assert_live_inventory(_adapter)
	var bind_calls: int = _adapter.bound_positions.size()
	var old_bind_calls: int = old_adapter.bound_positions.size()
	old_adapter.item_count = 1
	old_adapter.notify_data_set_changed()
	await _settle()
	assert_int(_adapter.bound_positions.size()).is_equal(bind_calls)
	assert_int(old_adapter.bound_positions.size()).is_equal(old_bind_calls)
	_assert_applied_layout()


func test_factory_adapter_replacement_discards_the_unbound_old_view() -> void:
	var old_adapter: TrackingAdapter = _adapter
	var replacement: TrackingAdapter = TrackingAdapter.new()
	replacement.item_count = 4
	replacement.revision = 11
	_adapters.append(replacement)
	old_adapter.on_create = func() -> void:
		old_adapter.on_create = Callable()
		_recycler.adapter = replacement
	await _mount()

	assert_object(_recycler.adapter).is_same(replacement)
	_adapter = replacement
	assert_int(old_adapter.create_calls).is_equal(1)
	assert_array(old_adapter.bound_positions).is_empty()
	assert_int(old_adapter.data_set_changed.get_connections().size()).is_zero()
	for view in old_adapter.roots:
		assert_bool(is_instance_valid(view)).is_false()
	for holder in old_adapter.holders:
		assert_bool(holder.is_bound()).is_false()
		assert_int(holder.get_binding_adapter_position()).is_equal(Holder.NO_POSITION)
	assert_int(_recycler.get_active_view_holder_count()).is_equal(4)
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	_assert_applied_layout()
	_assert_live_inventory(_adapter)


func test_hiding_an_outgoing_view_can_replace_adapter_without_old_holder_contamination() -> void:
	await _mount()
	var old_adapter: TrackingAdapter = _adapter
	var old_bind_calls: int = old_adapter.bound_positions.size()
	var replacement: TrackingAdapter = TrackingAdapter.new()
	replacement.item_count = 100
	replacement.revision = 12
	_adapters.append(replacement)
	var outgoing: Holder = _recycler.find_view_holder_for_adapter_position(0)
	var outgoing_view: Control = outgoing.get_item_view()
	outgoing_view.visibility_changed.connect(
		func() -> void:
			if _recycler.adapter == old_adapter and not outgoing_view.visible:
				_recycler.adapter = replacement
	)
	_recycler.scroll_vertical = 108
	await _settle()

	assert_object(_recycler.adapter).is_same(replacement)
	_adapter = replacement
	assert_int(old_adapter.bound_positions.size()).is_equal(old_bind_calls)
	assert_int(old_adapter.data_set_changed.get_connections().size()).is_zero()
	for view in old_adapter.roots:
		assert_bool(is_instance_valid(view)).is_false()
	for holder in old_adapter.holders:
		assert_bool(holder.is_bound()).is_false()
		assert_int(holder.get_binding_adapter_position()).is_equal(Holder.NO_POSITION)
	assert_int(_recycler.get_active_view_holder_count()).is_equal(6)
	assert_int(_recycler.get_recycled_view_holder_count()).is_zero()
	_assert_applied_layout()
	_assert_live_inventory(_adapter)


func test_teardown_releases_both_active_and_pooled_nodes() -> void:
	_recycler.size = Vector2(320.0, 640.0)
	await _mount()
	_recycler.size = INITIAL_SIZE
	await _settle()
	assert_int(_recycler.get_active_view_holder_count()).is_greater(0)
	assert_int(_recycler.get_recycled_view_holder_count()).is_greater(0)
	var roots: Array[ItemView] = _adapter.roots.duplicate()
	_recycler.queue_free()
	await _settle()

	assert_bool(is_instance_valid(_recycler)).is_false()
	for view in roots:
		assert_bool(is_instance_valid(view)).is_false()
	assert_int(_adapter.data_set_changed.get_connections().size()).is_zero()
	var bind_calls: int = _adapter.bound_positions.size()
	_adapter.notify_data_set_changed()
	await _settle()
	assert_int(_adapter.bound_positions.size()).is_equal(bind_calls)


func test_same_instance_can_be_removed_reconfigured_and_readded() -> void:
	await _mount()
	remove_child(_recycler)
	await _settle()
	assert_bool(_recycler.is_inside_tree()).is_false()
	var bind_calls: int = _adapter.bound_positions.size()
	var create_calls: int = _adapter.create_calls
	_adapter.item_count = 4
	_adapter.revision = 9
	_adapter.notify_data_set_changed()
	_recycler.size = Vector2(620.0, 200.0)
	_recycler.request_layout()
	await _settle()
	assert_int(_adapter.bound_positions.size()).is_equal(bind_calls)
	assert_int(_adapter.create_calls).is_equal(create_calls)
	await _mount()

	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i(0, 4))
	_assert_applied_layout()
	_assert_live_inventory(_adapter)
	for ready_state in _adapter.ready_when_bound:
		assert_bool(ready_state).is_true()
	var rebound_calls: int = _adapter.bound_positions.size()
	_adapter.revision = 10
	_adapter.notify_data_set_changed()
	await _settle()
	assert_array(_adapter.bound_positions.slice(rebound_calls)).contains_exactly_in_any_order(
		[0, 1, 2, 3]
	)
	_assert_applied_layout()


func _mount() -> void:
	add_child(_recycler)
	await _settle()


func _settle() -> void:
	# Content extent changes need native container sorting before visible reconciliation.
	for frame in range(SETTLE_FRAMES):
		await get_tree().process_frame


func _assert_applied_layout() -> void:
	var viewport_size: Vector2 = _recycler.get_layout_viewport_size()
	var expected: Vector2i = _layout.get_visible_range(
		_adapter.item_count, viewport_size, _recycler.get_v_scroll_bar().value
	)
	assert_vector(_recycler.get_visible_range()).is_equal(expected)
	_assert_vector_approx(
		_recycler.get_content_size(), _layout.get_content_size(_adapter.item_count, viewport_size)
	)
	assert_int(_recycler.get_active_view_holder_count()).is_equal(expected.y - expected.x)
	for position in range(expected.x, expected.y):
		var holder: Holder = _recycler.find_view_holder_for_adapter_position(position)
		assert_object(holder).is_not_null()
		if holder == null:
			continue
		assert_int(holder.get_binding_adapter_position()).is_equal(position)
		var view: ItemView = holder.get_item_view()
		assert_bool(view.is_visible_in_tree()).is_true()
		assert_bool(view.is_node_ready()).is_true()
		assert_int(view.ready_calls).is_equal(1)
		assert_str(view.button.text).is_equal("%d:%d" % [_adapter.revision, position])
		var expected_rect: Rect2 = _layout.get_item_rect(
			position, _adapter.item_count, viewport_size
		)
		_assert_vector_approx(view.position, expected_rect.position)
		_assert_vector_approx(view.size, expected_rect.size)
	assert_object(_recycler.find_view_holder_for_adapter_position(-1)).is_null()
	assert_object(_recycler.find_view_holder_for_adapter_position(expected.y)).is_null()
	assert_object(_recycler.find_view_holder_for_adapter_position(_adapter.item_count)).is_null()
	if expected.x > 0:
		assert_object(_recycler.find_view_holder_for_adapter_position(expected.x - 1)).is_null()


func _assert_empty_layout() -> void:
	assert_vector(_recycler.get_visible_range()).is_equal(Vector2i.ZERO)
	assert_vector(_recycler.get_content_size()).is_equal(Vector2.ZERO)
	assert_int(_recycler.get_active_view_holder_count()).is_zero()
	assert_object(_recycler.find_view_holder_for_adapter_position(0)).is_null()


func _assert_live_inventory(adapter: TrackingAdapter) -> void:
	var live_count: int = 0
	var hidden_count: int = 0
	var content_parent: Node = null
	for holder in adapter.holders:
		if not is_instance_valid(holder.get_item_view()):
			continue
		var view: Control = holder.get_item_view()
		live_count += 1
		assert_bool(view.is_inside_tree()).is_true()
		assert_bool(view.is_queued_for_deletion()).is_false()
		var parent: Node = view.get_parent()
		assert_object(parent).is_not_null()
		if parent != null:
			assert_str(parent.get_class()).is_equal("Control")
			assert_object(parent.get_parent()).is_same(_recycler)
			if content_parent == null:
				content_parent = parent
			assert_object(parent).is_same(content_parent)
		if not holder.is_bound():
			hidden_count += 1
			assert_bool(view.visible).is_false()
			assert_int(holder.get_binding_adapter_position()).is_equal(Holder.NO_POSITION)
		else:
			assert_bool(view.visible).is_true()
			(
				assert_object(
					_recycler.find_view_holder_for_adapter_position(
						holder.get_binding_adapter_position()
					)
				)
				. is_same(holder)
			)
	assert_int(live_count).is_equal(
		_recycler.get_active_view_holder_count() + _recycler.get_recycled_view_holder_count()
	)
	assert_int(hidden_count).is_equal(_recycler.get_recycled_view_holder_count())
	assert_int(hidden_count).is_less_equal(_recycler.recycled_pool_capacity)
	for position in adapter.positions_seen_in_recycle:
		assert_int(position).is_equal(Holder.NO_POSITION)


func _assert_vector_approx(actual: Vector2, expected: Vector2) -> void:
	assert_float(actual.x).is_equal_approx(expected.x, EPSILON)
	assert_float(actual.y).is_equal_approx(expected.y, EPSILON)
