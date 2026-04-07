@tool
class_name AssetPaletteManager
extends RefCounted

## Holds the active AssetPalette and persists it through AssetPaletteSerializer.

const DEFAULT_SAVE_PATH := "user://asset_placer_palettes.json"

static var _asset_palette: AssetPalette
static var _save_path: String


static func get_asset_palette() -> AssetPalette:
	assert(is_instance_valid(_asset_palette), "Cannot get AssetPalette when none is loaded.")
	return _asset_palette


static func load_asset_palette(load_path: String = DEFAULT_SAVE_PATH) -> void:
	if is_instance_valid(_asset_palette):
		_save_asset_palette()

	var new_palette := AssetPaletteSerializer.load_palette(load_path)
	_save_path = load_path

	var is_first_load := not is_instance_valid(_asset_palette)
	if is_first_load:
		_asset_palette = new_palette
		_connect_save()
	else:
		_disconnect_save()
		_asset_palette = new_palette
		_connect_save()


static func free_palette() -> void:
	if is_instance_valid(_asset_palette):
		_save_asset_palette()

	_disconnect_save()
	_asset_palette = null


static func _save_asset_palette() -> void:
	assert(is_instance_valid(_asset_palette), "Cannot save AssetPalette when none is loaded.")

	AssetPaletteSerializer.save_palette(_asset_palette, _save_path)


static func _on_palette_changed() -> void:
	_save_asset_palette()


static func _connect_save() -> void:
	_asset_palette.palette_changed.connect(_on_palette_changed)


static func _disconnect_save() -> void:
	if is_instance_valid(_asset_palette):
		_asset_palette.palette_changed.disconnect(_on_palette_changed)
