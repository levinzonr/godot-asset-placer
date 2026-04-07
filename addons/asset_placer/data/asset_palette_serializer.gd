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
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return AssetPalette.new()
	return _palette_from_dict(data)


static func save_palette(palette: AssetPalette, save_path: String) -> void:
	assert(is_instance_valid(palette), "AssetPaletteSerializer: Cannot save null palette.")

	var palette_wrappers: Array[Dictionary] = []
	for i in palette.get_palette_count():
		palette_wrappers.append({"slots": _serialize_slots(palette.get_palette(i))})

	var payload = {"version": FORMAT_VERSION, "palettes": palette_wrappers}
	var json_text = JSON.stringify(payload)
	var out = FileAccess.open(save_path, FileAccess.WRITE)
	if out == null:
		push_warning("AssetPaletteSerializer: could not write %s" % save_path)
		return
	out.store_string(json_text)
	out.close()


static func _palette_from_dict(data: Dictionary) -> AssetPalette:
	var ver = int(data.get("version", 0))
	if ver != FORMAT_VERSION:
		return AssetPalette.new()
	var slot_maps: Array[Dictionary] = []
	var raw_palettes = data.get("palettes", [])
	if typeof(raw_palettes) != TYPE_ARRAY or raw_palettes.is_empty():
		return AssetPalette.new()
	for entry in raw_palettes:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var raw_slots = entry.get("slots", {})
		slot_maps.append(_normalize_slots(raw_slots))
	if slot_maps.is_empty():
		return AssetPalette.new()
	return AssetPalette.new(slot_maps)


static func _normalize_slots(raw: Variant) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for k in raw:
		var ks = str(k)
		if not ks.is_valid_int():
			continue
		var idx = int(ks)
		if idx < 0 or idx > 9:
			continue
		var v = raw[k]
		if typeof(v) != TYPE_STRING or (v as String).is_empty():
			continue
		out[str(idx)] = v
	return out


static func _serialize_slots(slots: Dictionary) -> Dictionary:
	var out := {}
	for k in slots:
		var v = slots[k]
		if typeof(v) == TYPE_STRING and not (v as String).is_empty():
			out[str(k)] = v
	return out
