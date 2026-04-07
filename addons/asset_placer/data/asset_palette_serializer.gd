class_name AssetPaletteSerializer
extends RefCounted

const FORMAT_VERSION := 1


static func load_palette(load_path: String) -> AssetPalette:
	var file = FileAccess.open(load_path, FileAccess.READ)
	if file == null:
		return AssetPalette.new()
	var text = file.get_as_text()
	file.close()
	if text.strip_edges().is_empty():
		return AssetPalette.new()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return AssetPalette.new()
	return _decode_payload(parsed)


static func save_palette(palette: AssetPalette, save_path: String) -> void:
	assert(is_instance_valid(palette), "AssetPaletteSerializer: Cannot save null palette.")

	var palette_wrappers: Array[Dictionary] = []
	for palette_index in palette.get_palette_count():
		palette_wrappers.append(
			{"slots": _slots_to_json_array(palette.get_palette(palette_index))}
		)

	var payload = {"version": FORMAT_VERSION, "palettes": palette_wrappers}
	var json_text = JSON.stringify(payload)
	var output_file = FileAccess.open(save_path, FileAccess.WRITE)
	if output_file == null:
		push_warning("AssetPaletteSerializer: could not write %s" % save_path)
		return
	output_file.store_string(json_text)
	output_file.close()


static func _decode_payload(payload: Dictionary) -> AssetPalette:
	if int(payload.get("version", 0)) != FORMAT_VERSION:
		return AssetPalette.new()
	var raw_palettes = payload.get("palettes", [])
	if typeof(raw_palettes) != TYPE_ARRAY or raw_palettes.is_empty():
		return AssetPalette.new()
	var slot_rows: Array[PackedStringArray] = []
	for entry in raw_palettes:
		var row := _row_from_json_entry(entry)
		if row.is_empty():
			return AssetPalette.new()
		slot_rows.append(row)
	return AssetPalette.new(slot_rows)


static func _row_from_json_entry(entry: Variant) -> PackedStringArray:
	if typeof(entry) != TYPE_DICTIONARY:
		return PackedStringArray()
	var slots = (entry as Dictionary).get("slots")
	if typeof(slots) != TYPE_ARRAY:
		return PackedStringArray()
	var arr: Array = slots
	if arr.size() != AssetPalette.SLOT_COUNT:
		return PackedStringArray()
	var row := PackedStringArray()
	row.resize(AssetPalette.SLOT_COUNT)
	for i in AssetPalette.SLOT_COUNT:
		if typeof(arr[i]) != TYPE_STRING:
			return PackedStringArray()
		row[i] = arr[i]
	return row


static func _slots_to_json_array(slots: PackedStringArray) -> Array:
	var a: Array = []
	for i in AssetPalette.SLOT_COUNT:
		a.append(slots[i])
	return a
