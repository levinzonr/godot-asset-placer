@tool
class_name RecyclerView
extends ScrollContainer
## A vertically scrolling, virtualized collection with one homogeneous item view type.
##
## Owns all successfully created item views. Use adapter notifications for data changes
## and request_layout() after changing a layout manager's configuration. Refreshes are
## coalesced to the next frame, after native container sorting has a chance to settle.

const Adapter = preload("recycler_view_adapter.gd")
const LayoutManager = preload("recycler_view_layout_manager.gd")
const ViewHolder = preload("recycler_view_holder.gd")

## Maximum number of hidden, unbound holders retained between layout passes.
@export_range(0, 128, 1, "or_greater") var recycled_pool_capacity: int = 12:
	set(value):
		recycled_pool_capacity = maxi(value, 0)
		_trim_pool()

var adapter: Adapter:
	set(value):
		if adapter == value:
			return
		var previous := adapter
		if previous != null:
			previous.data_set_changed.disconnect(_on_data_set_changed)
		adapter = value
		_revision += 1
		if adapter != null:
			adapter.data_set_changed.connect(_on_data_set_changed)
		_clear_holders(previous)
		_rebind_all = true
		request_layout()

var layout_manager: LayoutManager:
	set(value):
		if layout_manager == value:
			return
		layout_manager = value
		_revision += 1
		request_layout()

var _content: Control
var _active_holders: Dictionary = {}
var _pool: Array[ViewHolder] = []
var _layout_viewport_size := Vector2.ZERO
var _content_size := Vector2.ZERO
var _visible_range := Vector2i.ZERO
var _layout_requested: bool = false
var _rebind_all: bool = true
var _revision: int = 0


func _init() -> void:
	horizontal_scroll_mode = SCROLL_MODE_DISABLED
	# Stable width avoids scrollbar visibility feeding back into grid layout.
	vertical_scroll_mode = SCROLL_MODE_SHOW_ALWAYS
	clip_contents = true
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_content = Control.new()
	_content.name = "Content"
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_content, false, Node.INTERNAL_MODE_BACK)
	_content.resized.connect(request_layout)
	resized.connect(request_layout)
	theme_changed.connect(request_layout)
	sort_children.connect(request_layout)
	get_v_scroll_bar().value_changed.connect(_on_scroll_value_changed)
	set_process(false)


func _enter_tree() -> void:
	request_layout.call_deferred()


func _ready() -> void:
	request_layout()


func _exit_tree() -> void:
	_revision += 1
	_layout_requested = false
	set_process(false)
	_clear_holders(adapter)
	_rebind_all = true
	_layout_viewport_size = Vector2.ZERO
	_content_size = Vector2.ZERO
	_content.custom_minimum_size = Vector2.ZERO


func _process(_delta: float) -> void:
	if not _layout_requested:
		set_process(false)
		return
	_layout_requested = false
	set_process(false)
	_refresh_layout(_revision)
	_trim_pool()


## Request geometry reconciliation without rebinding unchanged assignments.
func request_layout() -> void:
	_layout_requested = true
	if is_inside_tree():
		set_process(true)


## Usable native scroll area, excluding the scrollbar. Zero before initial layout.
func get_layout_viewport_size() -> Vector2:
	return _layout_viewport_size


func get_content_size() -> Vector2:
	return _content_size


## Half-open range of the current active assignments; no overscan.
func get_visible_range() -> Vector2i:
	return _visible_range


func find_view_holder_for_adapter_position(position: int) -> ViewHolder:
	return _active_holders.get(position)


func get_active_view_holder_count() -> int:
	return _active_holders.size()


func get_recycled_view_holder_count() -> int:
	return _pool.size()


func _on_scroll_value_changed(_value: float) -> void:
	request_layout()


func _on_data_set_changed() -> void:
	_revision += 1
	_rebind_all = true
	request_layout()


func _refresh_layout(revision: int) -> void:
	if not is_inside_tree() or not is_node_ready():
		return

	_layout_viewport_size = Vector2(_content.size.x, get_v_scroll_bar().page)
	var item_count := maxi(adapter.get_item_count(), 0) if adapter != null else 0
	_content_size = Vector2.ZERO
	if layout_manager != null:
		_content_size = layout_manager.get_content_size(item_count, _layout_viewport_size)

	# Native sorting owns content positioning, scroll ranges, and clamping. A changed
	# extent needs another frame before its viewport and scroll offset can be trusted.
	var minimum_size := Vector2(0.0, ceilf(_content_size.y))
	if _content.custom_minimum_size != minimum_size:
		_content.custom_minimum_size = minimum_size
		request_layout()
		return

	var target_range := Vector2i.ZERO
	if adapter != null and layout_manager != null:
		target_range = layout_manager.get_visible_range(
			item_count, _layout_viewport_size, get_v_scroll_bar().value
		)
	_reconcile_holders(target_range, item_count, revision)


func _reconcile_holders(target_range: Vector2i, item_count: int, revision: int) -> void:
	var binding_adapter := adapter
	for position: int in _active_holders.keys():
		if position < target_range.x or position >= target_range.y:
			var outgoing: ViewHolder = _active_holders[position]
			_active_holders.erase(position)
			if not _recycle_holder(outgoing, binding_adapter, revision):
				return

	var rebind := _rebind_all
	_rebind_all = false
	for position in range(target_range.x, target_range.y):
		var holder: ViewHolder = _active_holders.get(position)
		var needs_binding := rebind or holder == null
		if holder == null:
			holder = _obtain_holder(position, binding_adapter, revision)
			if holder == null:
				return

		var rect := layout_manager.get_item_rect(position, item_count, _layout_viewport_size)
		var item_view := holder.get_item_view()
		if not _apply_item_rect(item_view, rect, revision):
			return
		if needs_binding:
			if not binding_adapter.bind_view_holder(holder, position):
				_active_holders.erase(position)
				_destroy_holder(holder)
				continue
			if not _is_current(revision):
				return
			# Binding can change a control's minimum size. Item scenes must still fit
			# their slots; containers may arrange an item's interior, not this grid.
			if not _apply_item_rect(item_view, rect, revision):
				return
		item_view.show()
		if not _is_current(revision):
			return
	_visible_range = target_range


func _obtain_holder(position: int, binding_adapter: Adapter, revision: int) -> ViewHolder:
	var holder: ViewHolder = (
		_pool.pop_back() if not _pool.is_empty() else binding_adapter.create_view_holder(_content)
	)
	if holder == null:
		return null
	# The factory may synchronously replace the adapter before this holder is tracked.
	if not _is_current(revision):
		_destroy_holder(holder)
		return null
	_active_holders[position] = holder
	var item_view := holder.get_item_view()
	item_view.hide()
	if not _is_current(revision):
		return null
	if item_view.get_parent() == null:
		_content.add_child(item_view)
	if not _is_current(revision):
		return null
	return holder


func _apply_item_rect(item_view: Control, rect: Rect2, revision: int) -> bool:
	# Control geometry and visibility changes emit synchronous application signals.
	item_view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if not _is_current(revision):
		return false
	item_view.position = rect.position
	if not _is_current(revision):
		return false
	item_view.size = rect.size
	return _is_current(revision)


func _is_current(revision: int) -> bool:
	return revision == _revision and is_inside_tree() and not is_queued_for_deletion()


func _recycle_holder(holder: ViewHolder, binding_adapter: Adapter, revision: int) -> bool:
	binding_adapter.recycle_view_holder(holder)
	if not _is_current(revision):
		_destroy_holder(holder)
		return false
	holder.get_item_view().hide()
	if not _is_current(revision):
		_destroy_holder(holder)
		return false
	# Reuse all outgoing views within this pass before enforcing the idle pool limit.
	_pool.append(holder)
	return true


func _trim_pool() -> void:
	while _pool.size() > recycled_pool_capacity:
		_destroy_holder(_pool.pop_back())


func _clear_holders(binding_adapter: Adapter) -> void:
	var holders: Array = _active_holders.values()
	holders.append_array(_pool)
	_active_holders = {}
	_pool = []
	_visible_range = Vector2i.ZERO
	for holder: ViewHolder in holders:
		var item_view := holder.get_item_view()
		if is_instance_valid(item_view) and not item_view.is_queued_for_deletion():
			if binding_adapter != null and holder.is_bound():
				binding_adapter.recycle_view_holder(holder)
			_destroy_holder(holder)


func _destroy_holder(holder: ViewHolder) -> void:
	var item_view := holder.get_item_view()
	if is_instance_valid(item_view) and not item_view.is_queued_for_deletion():
		item_view.hide()
		item_view.queue_free()
