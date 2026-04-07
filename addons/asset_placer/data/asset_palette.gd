class_name AssetPalette
extends RefCounted

signal palette_changed

const SLOT_COUNT := 10

## Active palette index for the editor lives in AssetPaletteSessionState (in-memory), not here.
## Each entry: fixed [SLOT_COUNT] asset id strings; "" means empty slot.
var _palettes: Array[PackedStringArray] = []


func _init(palettes: Array = []):
	_palettes.clear()
	if palettes.is_empty():
		_palettes.append(_make_empty_slots())
	else:
		for item in palettes:
			assert(item is PackedStringArray, "AssetPalette: each row must be PackedStringArray")
			_palettes.append((item as PackedStringArray).duplicate())


func get_palette_count() -> int:
	return _palettes.size()


## Returns a duplicate of the slot ids for one palette (for serialization).
func get_palette(palette_index: int) -> PackedStringArray:
	if palette_index < 0 or palette_index >= _palettes.size():
		return PackedStringArray()
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
	var slots: PackedStringArray = _palettes[palette_index]
	slots[slot_index] = asset_id
	palette_changed.emit()


func clear_slot(palette_index: int, slot_index: int) -> void:
	if not _is_valid_slot_index(slot_index):
		return
	if palette_index < 0 or palette_index >= _palettes.size():
		return
	_palettes[palette_index][slot_index] = ""
	palette_changed.emit()


func clear_all_slots() -> void:
	for palette_index in _palettes.size():
		_palettes[palette_index] = _make_empty_slots()
	palette_changed.emit()


## Clears every slot on one palette; single palette_changed emit.
func clear_palette(palette_index: int) -> void:
	if palette_index < 0 or palette_index >= _palettes.size():
		return
	_palettes[palette_index] = _make_empty_slots()
	palette_changed.emit()


## Exchanges two slot entries on the same palette only (no global id removal).
func swap_slots(palette_index: int, slot_a: int, slot_b: int) -> void:
	if not _is_valid_slot_index(slot_a) or not _is_valid_slot_index(slot_b):
		return
	if palette_index < 0 or palette_index >= _palettes.size():
		return
	if slot_a == slot_b:
		return
	var slots: PackedStringArray = _palettes[palette_index]
	var tmp: String = slots[slot_a]
	slots[slot_a] = slots[slot_b]
	slots[slot_b] = tmp
	palette_changed.emit()


func get_asset_id_for_palette_slot(palette_index: int, slot_index: int) -> String:
	if not _is_valid_slot_index(slot_index):
		return ""
	if palette_index < 0 or palette_index >= _palettes.size():
		return ""
	return _palettes[palette_index][slot_index]


func _remove_asset_id_from_all_palettes(asset_id: String) -> void:
	if asset_id.is_empty():
		return
	for palette_index in _palettes.size():
		var slots: PackedStringArray = _palettes[palette_index]
		for slot_index in SLOT_COUNT:
			if slots[slot_index] == asset_id:
				slots[slot_index] = ""


static func _make_empty_slots() -> PackedStringArray:
	var slots := PackedStringArray()
	slots.resize(SLOT_COUNT)
	return slots


static func _is_valid_slot_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < SLOT_COUNT
