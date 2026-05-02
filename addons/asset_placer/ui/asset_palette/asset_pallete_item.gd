@tool
extends Control
class_name AssetPalletItem

@onready var button: Button = %Button
@onready var label: Label = %Label

signal on_clear_asset_click
signal on_add_asset_click

var _asset: AssetResource


func _ready() -> void:
	set_asset(null)
	button.pressed.connect(
		func():
			if _asset != null:
				on_clear_asset_click.emit()
			else:
				on_add_asset_click.emit()
	)


func set_index(index: int):
	label.text = str(index + 1)


func set_asset(asset: AssetResource):
	_asset = asset
	if asset and asset.has_resource():
		var thumbnail = AssetThumbnailTexture2D.new(asset.get_resource())
		button.icon = thumbnail
	else:
		button.icon = EditorIconTexture2D.new("Add")
