class_name AssetFolder
extends RefCounted

# Data

var path: String
var include_subfolders: bool
var rules: Array[AssetPlacerFolderRule] = []

# UI

## Intended to be read on UI creation. Don't call AssetLibrary.update_folder after changing.
var is_rules_visible := false


func _init(folder_path: String = "", include_subs: bool = false):
	self.path = folder_path
	self.include_subfolders = include_subs


## Returns all rules for this folder
func get_rules() -> Array[AssetPlacerFolderRule]:
	return rules


## Adds a rule to this folder
func add_rule(rule: AssetPlacerFolderRule):
	rules.append(rule)


## Removes a rule from this folder
func remove_rule(rule: AssetPlacerFolderRule):
	rules.erase(rule)


## Removes a rule at the given index
func remove_rule_at(index: int):
	if index >= 0 and index < rules.size():
		rules.remove_at(index)


## Returns true if given strings passes at least one filter rule.
func name_passes_filters(name: String) -> bool:
	for rule in rules:
		if rule.do_filter(name):
			return true
	return rules.is_empty()


## Returns true if an asset is added by the folder.
func has_asset(asset: AssetResource):
	if not name_passes_filters(asset.name):
		return false
	var is_parent_folder := path == asset.folder_path
	var is_sub_folder := include_subfolders and asset.folder_path.begins_with(path.path_join(""))
	return is_parent_folder or is_sub_folder


## Returns the number of configured rules
func get_rule_count() -> int:
	return rules.size()
