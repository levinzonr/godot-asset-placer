@tool
class_name RuleFactory
extends RefCounted

## All available rule scripts - single source of truth
const RULE_SCRIPTS = [
	preload("res://addons/asset_placer/data/folder/rules/add_to_collection_rule.gd"),
	preload("res://addons/asset_placer/data/folder/rules/filter_by_name_rule.gd"),
]

static var _type_map: Dictionary = {}


static func _get_type_map() -> Dictionary:
	if _type_map.is_empty():
		for script in RULE_SCRIPTS:
			var instance = script.new()
			_type_map[instance.get_type_id()] = script
	return _type_map


## Returns list of available rule type IDs
static func get_available_types() -> PackedStringArray:
	return PackedStringArray(_get_type_map().keys())


## Returns display name for a rule type
static func get_type_name(type_id: String) -> String:
	var rule = create(type_id)
	if rule:
		return rule.get_rule_name()
	return type_id


## Creates a new rule instance of the given type
static func create(type_id: String) -> AssetPlacerFolderRule:
	var type_map = _get_type_map()
	if not type_map.has(type_id):
		push_error("RuleFactory: Unknown rule type: %s" % type_id)
		return null

	var script = type_map[type_id]
	return script.new()


## Creates a rule instance from a dictionary
static func from_dict(data: Dictionary) -> AssetPlacerFolderRule:
	if not data.has("type"):
		push_error("RuleFactory: Rule dict missing 'type' field")
		return null

	var type_id = data["type"]
	var rule = create(type_id)
	if rule:
		rule.from_dict(data)
	return rule
