@tool
class_name CollapsibleSidePanel
extends HBoxContainer
## Horizontal drawer anchored on the **right**: a narrow toggle strip stays visible; the
## content region sits to its **left** and uses [code]custom_minimum_size.x[/code] so it grows
## left when expanded.
##
## **Placement:** Put this control on the **right** of its parent row so expansion reads as
## “to the left”. Typical pattern: last child of an [HBoxContainer] whose other children use
## [code]SIZE_EXPAND_FILL[/code], or anchor [code]anchor_left[/code] / [code]anchor_right[/code]
## to [code]1[/code] and drive width via offsets.

signal toggled(is_expanded: bool)

@export var expanded: bool = true:
	set(value):
		if expanded == value:
			_animate_expand_toggle = false
			return
		expanded = value
		var animated := _animate_expand_toggle
		_animate_expand_toggle = false
		if is_node_ready():
			_apply_expanded_state(animated)
		toggled.emit(expanded)

## When greater than [code]0[/code], width changes animate only when toggling via the toggle button.
@export_range(0.0, 2.0, 0.01, "or_greater") var animate_duration: float = 0.0

## Editor icon names for the toggle button ([EditorIconTexture2D]).
@export var collapsed_icon_name: StringName = &"GuiScrollArrowLeft":
	set(value):
		collapsed_icon_name = value
		if is_node_ready():
			_rebuild_toggle_icons()

@export var expanded_icon_name: StringName = &"GuiScrollArrowRight":
	set(value):
		expanded_icon_name = value
		if is_node_ready():
			_rebuild_toggle_icons()

## When greater than [code]0[/code], caps horizontal minimum width when expanded.
@export var max_expanded_width: float = 0.0:
	set(value):
		max_expanded_width = value
		if is_node_ready():
			_schedule_refresh_width()

var _animate_expand_toggle: bool = false
var _refresh_scheduled: bool = false
var _width_tween: Tween
var _icon_collapsed: Texture2D
var _icon_expanded: Texture2D

@onready var content_host: PanelContainer = %ContentHost
@onready var toggle_button: Button = %ToggleButton


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_schedule_refresh_width()


func _ready() -> void:
	content_host.child_entered_tree.connect(_on_content_child_entered)
	content_host.child_exiting_tree.connect(_on_content_child_exiting)
	for child in content_host.get_children():
		_hook_child_minimum_signals(child)
	toggle_button.pressed.connect(_on_toggle_pressed)
	_rebuild_toggle_icons()
	_apply_expanded_state(false)


func _on_toggle_pressed() -> void:
	_animate_expand_toggle = animate_duration > 0.0
	expanded = not expanded


func _on_content_child_entered(node: Node) -> void:
	_hook_child_minimum_signals(node)
	_schedule_refresh_width()


func _on_content_child_exiting(node: Node) -> void:
	_unhook_child_minimum_signals(node)
	_schedule_refresh_width()


func _hook_child_minimum_signals(node: Node) -> void:
	if node is Control:
		var c := node as Control
		if not c.minimum_size_changed.is_connected(_schedule_refresh_width):
			c.minimum_size_changed.connect(_schedule_refresh_width)


func _unhook_child_minimum_signals(node: Node) -> void:
	if node is Control:
		var c := node as Control
		if c.minimum_size_changed.is_connected(_schedule_refresh_width):
			c.minimum_size_changed.disconnect(_schedule_refresh_width)


func _schedule_refresh_width() -> void:
	if _refresh_scheduled:
		return
	_refresh_scheduled = true
	call_deferred("_deferred_refresh_width")


func _deferred_refresh_width() -> void:
	_refresh_scheduled = false
	_refresh_content_width()


func _measure_intrinsic_content_width() -> float:
	var host := content_host
	var restore := host.custom_minimum_size
	host.custom_minimum_size.x = 0.0
	var w := host.get_combined_minimum_size().x
	host.custom_minimum_size = restore
	return w


func _clamp_expanded_width(w: float) -> float:
	if max_expanded_width > 0.0:
		return mini(w, max_expanded_width)
	return w


func _refresh_content_width() -> void:
	if not is_instance_valid(content_host):
		return
	var measured := ceilf(_clamp_expanded_width(_measure_intrinsic_content_width()))
	if expanded:
		_snapply_content_width(measured)


func _kill_width_tween() -> void:
	if _width_tween != null:
		_width_tween.kill()


func _snapply_content_width(x: float) -> void:
	_kill_width_tween()
	var y := content_host.custom_minimum_size.y
	content_host.custom_minimum_size = Vector2(x, y)


func _apply_expanded_state(animated: bool) -> void:
	if not is_instance_valid(content_host):
		return
	_update_toggle_icon()
	if expanded:
		var target := ceilf(_clamp_expanded_width(_measure_intrinsic_content_width()))
		if animated and animate_duration > 0.0:
			_tween_content_width_to(target)
		else:
			_snapply_content_width(target)
	else:
		if animated and animate_duration > 0.0:
			_tween_content_width_to(0.0)
		else:
			_snapply_content_width(0.0)


func _tween_content_width_to(to_x: float) -> void:
	_kill_width_tween()
	var y := content_host.custom_minimum_size.y
	var from_x := content_host.custom_minimum_size.x
	_width_tween = create_tween()
	_width_tween.set_parallel(false)
	_width_tween.tween_method(
		func(x: float): content_host.custom_minimum_size = Vector2(x, y),
		from_x,
		to_x,
		animate_duration
	)


func _rebuild_toggle_icons() -> void:
	var collapsed_tex := EditorIconTexture2D.new()
	collapsed_tex.icon_name = collapsed_icon_name
	var expanded_tex := EditorIconTexture2D.new()
	expanded_tex.icon_name = expanded_icon_name
	_icon_collapsed = collapsed_tex
	_icon_expanded = expanded_tex
	_update_toggle_icon()


func _update_toggle_icon() -> void:
	if not is_instance_valid(toggle_button):
		return
	if _icon_collapsed == null or _icon_expanded == null:
		return
	toggle_button.icon = _icon_expanded if expanded else _icon_collapsed
