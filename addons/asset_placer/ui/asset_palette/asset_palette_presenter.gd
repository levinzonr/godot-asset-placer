# gdlint: disable=max-public-methods
class_name AssetPalettePresenter
extends RefCounted

signal palette_change(
	active_palette_index: int, palette_count: int, slot_assets: Array[AssetResource]
)

var _session_state: AssetPaletteSessionState


func _init(session_state: AssetPaletteSessionState):
	_session_state = session_state


## Call after construction to connect signals and emit [signal palette_change] once with the initial state.
func ready() -> void:
	_connect_signals()
	_emit_presentation()


func shutdown() -> void:
	_disconnect_signals()


func get_active_palette_index() -> int:
	return _session_state.get_active_palette_index()


func get_palette_count() -> int:
	return AssetPaletteManager.get_asset_palette().get_palette_count()


func set_active_palette_index(index: int) -> void:
	_session_state.set_active_palette_index(index)


func next_palette() -> void:
	_session_state.next_palette()


func previous_palette() -> void:
	_session_state.previous_palette()


func get_resolved_slots() -> Array[AssetResource]:
	return _build_resolved_slots()


func get_asset_at_slot(slot_index: int) -> AssetResource:
	if slot_index < 0 or slot_index >= AssetPalette.SLOT_COUNT:
		return null
	var active_index := _session_state.get_active_palette_index()
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var asset_library := AssetLibraryManager.get_asset_library()
	var asset_id: String = asset_palette.get_asset_id_for_palette_slot(
		active_index, slot_index
	)
	if asset_id.is_empty():
		return null
	return asset_library.get_asset(asset_id)


func add_or_assign_asset(slot_index: int, asset: AssetResource) -> void:
	if not is_instance_valid(asset):
		return
	AssetPaletteManager.get_asset_palette().set_slot_asset(
		_session_state.get_active_palette_index(), slot_index, asset.id
	)


func remove_slot(slot_index: int) -> void:
	AssetPaletteManager.get_asset_palette().clear_slot(
		_session_state.get_active_palette_index(), slot_index
	)


func swap_slots(slot_a: int, slot_b: int) -> void:
	AssetPaletteManager.get_asset_palette().swap_slots(
		_session_state.get_active_palette_index(), slot_a, slot_b
	)


func clear_active_palette() -> void:
	AssetPaletteManager.get_asset_palette().clear_palette(
		_session_state.get_active_palette_index()
	)


func _connect_signals() -> void:
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var asset_library := AssetLibraryManager.get_asset_library()
	asset_palette.palette_changed.connect(_on_palette_changed)
	asset_library.assets_changed.connect(_on_library_assets_changed)
	_session_state.active_palette_index_changed.connect(_on_session_active_index_changed)


func _disconnect_signals() -> void:
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var asset_library := AssetLibraryManager.get_asset_library()
	if asset_palette.palette_changed.is_connected(_on_palette_changed):
		asset_palette.palette_changed.disconnect(_on_palette_changed)
	if asset_library.assets_changed.is_connected(_on_library_assets_changed):
		asset_library.assets_changed.disconnect(_on_library_assets_changed)
	if _session_state.active_palette_index_changed.is_connected(_on_session_active_index_changed):
		_session_state.active_palette_index_changed.disconnect(_on_session_active_index_changed)


func _on_palette_changed() -> void:
	_emit_presentation()


func _on_library_assets_changed() -> void:
	_emit_presentation()


func _on_session_active_index_changed() -> void:
	_emit_presentation()


func _emit_presentation() -> void:
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var palette_count := asset_palette.get_palette_count()
	var slot_assets: Array[AssetResource] = _build_resolved_slots()
	var active_index := _session_state.get_active_palette_index()
	palette_change.emit(active_index, palette_count, slot_assets)


func _build_resolved_slots() -> Array[AssetResource]:
	var resolved_slots: Array[AssetResource] = []
	var asset_palette := AssetPaletteManager.get_asset_palette()
	var asset_library := AssetLibraryManager.get_asset_library()
	var active_index := _session_state.get_active_palette_index()
	for slot_index in AssetPalette.SLOT_COUNT:
		var asset_id: String = asset_palette.get_asset_id_for_palette_slot(
			active_index, slot_index
		)
		if asset_id.is_empty():
			resolved_slots.append(null)
		else:
			resolved_slots.append(asset_library.get_asset(asset_id))
	return resolved_slots
