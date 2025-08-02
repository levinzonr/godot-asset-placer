@tool
extends Button
class_name Chip

@export var backgroundColor: Color = Color(0, 0, 0, 0.5): set = set_background_color
@export var corner_radius: int = 32: set = set_corner_radius
@export var content_margin_vertical: int = 4: set = set_content_margin_v
@export var content_margin_horizontal: int = 8: set = set_content_margin_h

var asset_collection: AssetCollection

func _ready():
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_color", Color.BLACK)
	_update_stylebox()
	_update_minimum_size()

func set_background_color(color: Color):
	backgroundColor = color
	_update_stylebox()

func set_corner_radius(radius: int):
	corner_radius = radius
	_update_stylebox()

func set_content_margin_v(margin):
	content_margin_vertical = margin
	_update_stylebox()
	_update_minimum_size()

func set_content_margin_h(margin):
	content_margin_horizontal = margin
	_update_stylebox()
	_update_minimum_size()

func _update_stylebox():
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = backgroundColor
	stylebox.set_corner_radius_all(corner_radius)
	stylebox.content_margin_left = content_margin_horizontal
	stylebox.content_margin_right = content_margin_horizontal
	stylebox.content_margin_bottom = content_margin_vertical
	stylebox.content_margin_top = content_margin_vertical
	add_theme_stylebox_override("normal", stylebox)

func _update_minimum_size():
	custom_minimum_size = Vector2(content_margin_horizontal * 2, content_margin_vertical * 2) + get_minimum_size()
