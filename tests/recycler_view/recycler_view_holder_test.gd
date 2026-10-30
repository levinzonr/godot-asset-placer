extends GdUnitTestSuite

const Holder = preload(
	"res://addons/asset_placer/ui/components/recycler_view/recycler_view_holder.gd"
)


class LabelHolder:
	extends Holder

	var label: Label

	func _init(item_view: Control) -> void:
		super(item_view)
		label = item_view.get_node("Label")


func test_new_holder_wraps_the_view_and_has_no_position() -> void:
	var item_view: Control = auto_free(Control.new())
	var holder := Holder.new(item_view)
	assert_object(holder.get_item_view()).is_same(item_view)
	assert_int(holder.get_binding_adapter_position()).is_equal(Holder.NO_POSITION)
	assert_int(Holder.NO_POSITION).is_equal(-1)
	assert_bool(holder.is_bound()).is_false()
	assert_object(item_view.get_parent()).is_null()


func test_subclass_can_cache_child_references() -> void:
	var item_view: Control = auto_free(Control.new())
	var label := Label.new()
	label.name = "Label"
	item_view.add_child(label)
	var holder := LabelHolder.new(item_view)
	assert_object(holder.get_item_view()).is_same(item_view)
	assert_object(holder.label).is_same(label)


func test_releasing_a_holder_does_not_free_or_reparent_its_view() -> void:
	var parent: Control = auto_free(Control.new())
	var item_view := Control.new()
	parent.add_child(item_view)
	var holder := Holder.new(item_view)
	var holder_ref: WeakRef = weakref(holder)
	holder = null
	assert_object(holder_ref.get_ref()).is_null()
	assert_bool(is_instance_valid(item_view)).is_true()
	assert_object(item_view.get_parent()).is_same(parent)
	assert_bool(item_view.is_queued_for_deletion()).is_false()


func test_freeing_the_view_does_not_free_the_holder() -> void:
	var item_view := Control.new()
	var holder := Holder.new(item_view)
	item_view.free()
	assert_bool(is_instance_valid(holder)).is_true()
	assert_bool(is_instance_valid(holder.get_item_view())).is_false()
	assert_bool(holder.is_bound()).is_false()
