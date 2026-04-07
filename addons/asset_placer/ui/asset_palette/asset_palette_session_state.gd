class_name AssetPaletteSessionState
extends RefCounted

signal active_palette_index_changed

var _active_palette_index: int = 0


func _init():
	AssetPaletteManager.get_asset_palette().palette_changed.connect(_on_palette_data_changed)


func shutdown() -> void:
	var asset_palette := AssetPaletteManager.get_asset_palette()
	if asset_palette.palette_changed.is_connected(_on_palette_data_changed):
		asset_palette.palette_changed.disconnect(_on_palette_data_changed)


func get_active_palette_index() -> int:
	return _active_palette_index


func set_active_palette_index(index: int) -> void:
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	if palette_count < 1:
		return
	var max_index := palette_count - 1
	var new_index := clampi(index, 0, max_index)
	if new_index == _active_palette_index:
		return
	_active_palette_index = new_index
	active_palette_index_changed.emit()


func next_palette() -> void:
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	if palette_count < 1:
		return
	var next_palette_index := _active_palette_index + 1
	if next_palette_index >= palette_count:
		return
	_active_palette_index = next_palette_index
	active_palette_index_changed.emit()


func previous_palette() -> void:
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	if palette_count < 1:
		return
	var previous_index := (_active_palette_index - 1 + palette_count) % palette_count
	if previous_index == _active_palette_index:
		return
	_active_palette_index = previous_index
	active_palette_index_changed.emit()


func _on_palette_data_changed() -> void:
	var previous_index := _active_palette_index
	_clamp_active_index()
	if _active_palette_index != previous_index:
		active_palette_index_changed.emit()


func _clamp_active_index() -> void:
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	if palette_count < 1:
		return
	_active_palette_index = clampi(_active_palette_index, 0, palette_count - 1)
