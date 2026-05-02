@tool
extends Control

@onready var h_box_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer
@onready var presenter := AssetPalettePresenter.new()
var _item_resource = preload("res://addons/asset_placer/ui/asset_palette/asset_pallete_item.tscn")


func _ready() -> void:
	presenter.palette_change.connect(_show_pallete_items)
	presenter.ready(0)


func _show_pallete_items(pallete_items: Array[AssetResource]) -> void:
	for child in h_box_container.get_children():
		child.queue_free()
	for index in range(pallete_items.size()):
		var item = pallete_items[index]
		var item_instance = _item_resource.instantiate() as AssetPalletItem
		h_box_container.add_child(item_instance)
		item_instance.set_index(index)
		item_instance.set_asset(item)
		item_instance.on_add_asset_click.connect(
			func():
				AssetPickerDialog.open(
					func(asset: AssetResource): _configure_shortcut_key(asset, index)
				)
		)
		item_instance.on_clear_asset_click.connect(func(): presenter.remove_slot(index))


func _configure_shortcut_key(item: AssetResource, shortcut_key: int) -> void:
	presenter.add_or_assign_asset(shortcut_key, item)
