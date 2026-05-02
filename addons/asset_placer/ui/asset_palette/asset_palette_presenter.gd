# gdlint: disable=max-public-methods
class_name AssetPalettePresenter
extends RefCounted

signal palette_change(slot_assets: Array[AssetResource])

var _pallete_index: int = 0


## Call after construction to connect signals and emit [signal palette_change] once with the initial state.
func ready(palette_index: int) -> void:
	self._pallete_index = palette_index
	_connect_signals()
	_emit_pallete_change()


func shutdown() -> void:
	_disconnect_signals()


func get_palette_count() -> int:
	return APEditorSettingsManager.get_editor_settings().get_asset_palette().get_palette_count()


func set_palette_index(palette_index: int) -> void:
	self._pallete_index = palette_index
	_emit_pallete_change()


func get_resolved_slots() -> Array[AssetResource]:
	return _build_resolved_slots()



func add_or_assign_asset(slot_index: int, asset: AssetResource) -> void:
	if not is_instance_valid(asset):
		return
	APEditorSettingsManager.get_editor_settings().get_asset_palette().set_slot_asset(
		_pallete_index, slot_index, asset.id
	)


func remove_slot(slot_index: int) -> void:
	APEditorSettingsManager.get_editor_settings().get_asset_palette().clear_slot(
		_pallete_index, slot_index
	)


func swap_slots(slot_a: int, slot_b: int) -> void:
	APEditorSettingsManager.get_editor_settings().get_asset_palette().swap_slots(
		_pallete_index, slot_a, slot_b
	)


func clear_active_palette() -> void:
	APEditorSettingsManager.get_editor_settings().get_asset_palette().clear_palette(_pallete_index)


func _connect_signals() -> void:
	var asset_palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	var asset_library := AssetLibraryManager.get_asset_library()
	asset_palette.palette_changed.connect(_on_palette_changed)
	asset_library.assets_changed.connect(_on_library_assets_changed)


func _disconnect_signals() -> void:
	var asset_palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	var asset_library := AssetLibraryManager.get_asset_library()
	if asset_palette.palette_changed.is_connected(_on_palette_changed):
		asset_palette.palette_changed.disconnect(_on_palette_changed)
	if asset_library.assets_changed.is_connected(_on_library_assets_changed):
		asset_library.assets_changed.disconnect(_on_library_assets_changed)


func _on_palette_changed() -> void:
	_emit_pallete_change()


func _on_library_assets_changed() -> void:
	_emit_pallete_change()


func _emit_pallete_change() -> void:
	var asset_palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	var slot_assets: Array[AssetResource] = _build_resolved_slots()
	palette_change.emit(slot_assets)


func _build_resolved_slots() -> Array[AssetResource]:
	var resolved_slots: Array[AssetResource] = []
	var asset_palette := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	var asset_library := AssetLibraryManager.get_asset_library()
	for slot_index in AssetPalette.SLOT_COUNT:
		var asset_id: String = asset_palette.get_asset_id_for_palette_slot(
			_pallete_index, slot_index
		)
		if asset_id.is_empty():
			resolved_slots.append(null)
		else:
			resolved_slots.append(asset_library.get_asset(asset_id))
	return resolved_slots
