@tool
class_name AssetPalletItem
extends Control

signal on_clear_asset_click
signal on_add_asset_click

@export var button_size: Vector2 = Vector2(64, 64):
	set(value):
		button_size = value
		_apply_button_geometry_and_state()

@export var configurable: bool = true:
	set(value):
		configurable = value
		_apply_button_geometry_and_state()

var _asset: AssetResource
var _index: int = 0
@onready var button: Button = %Button
@onready var label: Label = %Label


func _ready() -> void:
	button.pressed.connect(
		func():
			if configurable:
				on_add_asset_click.emit()
	)
	button.gui_input.connect(_on_button_gui_input)
	_apply_button_geometry_and_state()
	set_asset(null)
	set_index(_index)


func set_index(index: int):
	_index = index
	if not is_node_ready():
		return
	label.text = str(index + 1)


func set_asset(asset: AssetResource):
	_asset = asset
	_update_button_icon()


func _apply_button_geometry_and_state() -> void:
	if not is_node_ready():
		return
	button.custom_minimum_size = button_size
	button.disabled = not configurable
	_update_button_icon()


func _update_button_icon() -> void:
	if not is_node_ready():
		return
	if _asset != null and _asset.has_resource():
		button.tooltip_text = _asset.name
		button.icon = AssetThumbnailTexture2D.new(_asset.get_resource())
	elif configurable:
		button.icon = EditorIconTexture2D.new("Add")
	else:
		button.icon = EditorIconTexture2D.new("GuiRadioUnchecked")


func _on_button_gui_input(event: InputEvent) -> void:
	if not configurable or _asset == null:
		return
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_RIGHT
	):
		on_clear_asset_click.emit()
