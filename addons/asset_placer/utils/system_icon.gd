@tool
extends Texture2D
class_name EditorIconTexture2D

@export var icon_name: StringName = &"Node2D"

var _resolved_icon: Texture2D = null;

func _init(name: String =  &"Node2D"):
	self.icon_name = name

func _resolve():
	if not Engine.is_editor_hint():
		return # Don’t try resolving outside editor

	var theme := EditorInterface.get_editor_theme()
	if theme and icon_name != "":
		if theme.has_icon(icon_name, "EditorIcons"):
			_resolved_icon = theme.get_icon(icon_name, "EditorIcons")
		else:
			_resolved_icon = theme.get_icon(&"Node3D", "EditorIcons")

# Called automatically by Control.draw() and other systems
func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, transpose: bool) -> void:
	_resolve()
	if _resolved_icon:
		_resolved_icon.draw(to_canvas_item, pos, modulate, transpose)

func _draw_rect(to_canvas_item: RID, rect: Rect2, tile: bool, modulate: Color, transpose: bool) -> void:
	_resolve()
	if _resolved_icon:
		_resolved_icon.draw_rect(to_canvas_item, rect, tile, modulate, transpose)

func _draw_rect_region(to_canvas_item: RID, rect: Rect2, src_rect: Rect2, modulate: Color, transpose: bool, clip_uv: bool) -> void:
	_resolve()
	if _resolved_icon:
		_resolved_icon.draw_rect_region(to_canvas_item, rect, src_rect, modulate, transpose, clip_uv)

func _get_width() -> int:
	_resolve()
	return _resolved_icon.get_width() if _resolved_icon else 1

func _get_height() -> int:
	_resolve()
	return _resolved_icon.get_height() if _resolved_icon else 1

func _has_alpha() -> bool:
	_resolve()
	return _resolved_icon.has_alpha() if _resolved_icon else true

func _is_pixel_opaque(x: int, y: int) -> bool:
	_resolve()
	return _resolved_icon.is_pixel_opaque(x, y) if _resolved_icon else false

func get_image() -> Image:
	_resolve()
	return _resolved_icon.get_image() if _resolved_icon else Image.new()

func get_size() -> Vector2:
	return Vector2(_get_width(), _get_height())
