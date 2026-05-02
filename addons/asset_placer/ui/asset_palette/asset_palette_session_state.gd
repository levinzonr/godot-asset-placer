class_name AssetPaletteSessionState
extends RefCounted

## In-memory active palette index for the editor session (not persisted, not in palette JSON).

signal active_palette_index_changed

static var instance: AssetPaletteSessionState = null

var _active_palette_index: int = 0


func _init():
	instance = self
	APEditorSettingsManager.get_editor_settings().get_asset_palette().palette_changed.connect(
		_on_palette_data_changed
	)


func shutdown() -> void:
	var asset_palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	if asset_palette.palette_changed.is_connected(_on_palette_data_changed):
		asset_palette.palette_changed.disconnect(_on_palette_data_changed)


func get_active_palette_index() -> int:
	return _active_palette_index


func get_asset_at_slot(slot_index: int) -> AssetResource:
	if slot_index < 0 or slot_index >= AssetPalette.SLOT_COUNT:
		return null
	var palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	var asset_id: String = palette.get_asset_id_for_palette_slot(_active_palette_index, slot_index)
	if asset_id.is_empty():
		return null
	return AssetLibraryManager.get_asset_library().get_asset(asset_id)


func set_active_palette_index(index: int) -> void:
	var asset_palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	if palette_count < 1:
		return
	var max_index := palette_count - 1
	var new_index := clampi(index, 0, max_index)
	if new_index == _active_palette_index:
		return
	_active_palette_index = new_index
	active_palette_index_changed.emit()


func next_palette() -> bool:
	return find_next_non_empty_palette(1)


func previous_palette() -> bool:
	return find_next_non_empty_palette(-1)


func find_next_non_empty_palette(direction: int) -> bool:
	var asset_palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	if palette_count < 1:
		return false
	var current_index := _active_palette_index
	for i in range(palette_count):
		var next_index := (current_index + direction + palette_count) % palette_count
		if not asset_palette.is_palette_empty(next_index):
			_active_palette_index = next_index
			active_palette_index_changed.emit()
			return true
	return false


func _on_palette_data_changed() -> void:
	var previous_index := _active_palette_index
	_clamp_active_index()
	if _active_palette_index != previous_index:
		active_palette_index_changed.emit()


func _clamp_active_index() -> void:
	var asset_palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	if palette_count < 1:
		return
	_active_palette_index = clampi(_active_palette_index, 0, palette_count - 1)
