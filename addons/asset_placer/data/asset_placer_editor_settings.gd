@tool
class_name AssetPlacerEditorSettings
extends Resource

## Resource for holding editor settings specific to a project.

## Holds a AssetResource id as a key and a UNIX timestamp as value.
@export_storage var _assets_time_placed: Dictionary[String, float] = {}


func get_assets_time_placed() -> Dictionary[String, float]:
	return _assets_time_placed


func update_asset_time_placed(asset_id: String):
	_assets_time_placed[asset_id] = Time.get_unix_time_from_system()
	emit_changed()


func remove_asset_time_placed(asset_id: String):
	if _assets_time_placed.has(asset_id):
		_assets_time_placed.erase(asset_id)


func _emit_all_changed():
	emit_changed()
