@tool
class_name AssetPalleteContainer
extends HBoxContainer

signal on_delete_pallete_click

const PALETTE_BUTTON_BASE := Vector2(64, 64)

var _item_resource = preload("res://addons/asset_placer/ui/asset_palette/asset_pallete_item.tscn")
var _pallete_index: int = 0
@onready var presenter := AssetPalettePresenter.new()


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	alignment = AlignmentMode.ALIGNMENT_CENTER
	presenter.palette_change.connect(_show_pallete_items)
	AssetPlacerSettingsRepository.instance.settings_changed.connect(_on_placer_settings_changed)
	presenter.ready(_pallete_index)


func _exit_tree() -> void:
	var repo := AssetPlacerSettingsRepository.instance
	if repo.settings_changed.is_connected(_on_placer_settings_changed):
		repo.settings_changed.disconnect(_on_placer_settings_changed)


func get_pallete_index() -> int:
	return _pallete_index


func _show_pallete_items(pallete_items: Array[AssetResource]) -> void:
	for child in get_children():
		child.queue_free()
	add_pallete_label()
	for index in range(pallete_items.size()):
		var item = pallete_items[index]
		var item_instance = _item_resource.instantiate() as AssetPalletItem
		add_child(item_instance)
		item_instance.button_size = _palette_item_button_size()
		item_instance.set_index(index)
		item_instance.set_asset(item)
		item_instance.on_add_asset_click.connect(
			func():
				AssetPickerDialog.open(
					func(asset: AssetResource): _configure_shortcut_key(asset, index)
				)
		)
		item_instance.on_clear_asset_click.connect(func(): presenter.remove_slot(index))

	add_delete_button()


func _palette_item_button_size() -> Vector2:
	return (
		PALETTE_BUTTON_BASE
		* AssetPlacerSettingsRepository.instance.get_settings().palette_item_scale
	)


func _on_placer_settings_changed(_settings: AssetPlacerSettings) -> void:
	for child in get_children():
		if child is AssetPalletItem:
			(child as AssetPalletItem).button_size = _palette_item_button_size()


func _configure_shortcut_key(item: AssetResource, shortcut_key: int) -> void:
	presenter.add_or_assign_asset(shortcut_key, item)


func add_pallete_label():
	var label = Label.new()
	label.text = "Pallete #" + str(_pallete_index + 1)
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(label)


func add_delete_button():
	var delete_button = Button.new()
	delete_button.icon = EditorIconTexture2D.new("Remove")
	delete_button.expand_icon = false
	delete_button.size = Vector2(24, 24)
	delete_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if _pallete_index == 0:
		delete_button.disabled = true
		delete_button.modulate.a = 0
	delete_button.pressed.connect(func(): on_delete_pallete_click.emit())
	add_child(delete_button)


static func create_pallete_container(pallete_index: int = 0) -> AssetPalleteContainer:
	var container = AssetPalleteContainer.new()
	container._pallete_index = pallete_index
	return container
