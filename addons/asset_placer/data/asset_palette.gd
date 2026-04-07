# gdlint: disable=max-public-methods
## In-memory asset palette: multiple palettes of up to 10 slots (keys 1–9, 0), sparse slot maps.
## Which palette is "active" for the editor is not part of this model (stored elsewhere when implemented).
class_name AssetPalette
extends RefCounted

signal palette_changed

const SLOT_COUNT := 10

## Each entry: slot index string ("0".."9") -> asset id string.
var _palettes: Array[Dictionary] = []


func _init(palettes: Array[Dictionary] = []):
	if palettes.is_empty():
		_palettes = [{}]
	else:
		_palettes = palettes


func get_palette_count() -> int:
	return _palettes.size()


## Returns a shallow duplicate of the slot map for one palette (for serialization).
func get_palette(palette_index: int) -> Dictionary:
	if palette_index < 0 or palette_index >= _palettes.size():
		return {}
	return _palettes[palette_index].duplicate()


## Assigns asset_id to slot on palette palette_index; removes that id from every other slot (all palettes).
func set_slot_asset(palette_index: int, slot_index: int, asset_id: String) -> void:
	if not _is_valid_slot_index(slot_index):
		push_warning("AssetPalette: slot_index must be 0..9")
		return
	if palette_index < 0 or palette_index >= _palettes.size():
		push_warning("AssetPalette: invalid palette_index")
		return
	if asset_id.is_empty():
		clear_slot(palette_index, slot_index)
		return
	_remove_asset_id_from_all_palettes(asset_id)
	var slots: Dictionary = _palettes[palette_index]
	slots[str(slot_index)] = asset_id
	palette_changed.emit()


func clear_slot(palette_index: int, slot_index: int) -> void:
	if not _is_valid_slot_index(slot_index):
		return
	if palette_index < 0 or palette_index >= _palettes.size():
		return
	var slots: Dictionary = _palettes[palette_index]
	slots.erase(str(slot_index))
	palette_changed.emit()


func clear_all_slots() -> void:
	for i in _palettes.size():
		_palettes[i] = {}
	palette_changed.emit()


func get_asset_id_for_palette_slot(palette_index: int, slot_index: int) -> String:
	if not _is_valid_slot_index(slot_index):
		return ""
	if palette_index < 0 or palette_index >= _palettes.size():
		return ""
	var slots: Dictionary = _palettes[palette_index]
	var id = slots.get(str(slot_index), "")
	return id if id is String else ""


func _remove_asset_id_from_all_palettes(asset_id: String) -> void:
	if asset_id.is_empty():
		return
	for pi in _palettes.size():
		var slots: Dictionary = _palettes[pi]
		var to_erase: Array[String] = []
		for sk in slots:
			if slots[sk] == asset_id:
				to_erase.append(sk)
		for sk in to_erase:
			slots.erase(sk)


static func _is_valid_slot_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < SLOT_COUNT
