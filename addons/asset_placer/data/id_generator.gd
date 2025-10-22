extends RefCounted
class_name AssetPlacerIdGenerator


const KEY: String = "asset_placer/internal/last_int"

func _init():
	pass

func next_int() -> int:
	var last_int = ProjectSettings.get_setting(KEY, -1)
	var new_int = last_int + 1
	ProjectSettings.set_setting(KEY, new_int)
	return new_int
