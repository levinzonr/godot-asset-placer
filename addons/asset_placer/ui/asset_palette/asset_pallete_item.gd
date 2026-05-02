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

@onready var button: Button = %Button
@onready var label: Label = %Label


func _ready() -> void:
	button.pressed.connect(
		func():
			if _asset != null:
				on_clear_asset_click.emit()
			else:
				on_add_asset_click.emit()
	)
	_apply_button_geometry_and_state()
	set_asset(null)


func set_index(index: int):
	label.text = str(index + 1)


func set_asset(asset: AssetResource):
	_asset = asset
	_update_button_icon()


func _apply_button_geometry_and_state() -> void:
	if not is_node_ready():
		return
	button.custom_minimum_size = button_size
	_update_button_icon()


func _update_button_icon() -> void:
	if not is_node_ready():
		return
	if _asset != null and _asset.has_resource():
		button.icon = AssetThumbnailTexture2D.new(_asset.get_resource())
	elif configurable:
		button.icon = EditorIconTexture2D.new("Add")
	else:
		button.icon = EditorIconTexture2D.new("GuiRadioUnchecked")
