class_name AssetFolder
extends RefCounted

var path: String
var include_subfolders: bool
var rules: Array[AssetPlacerFolderRule] = []


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


## Returns the number of configured rules
func get_rule_count() -> int:
	return rules.size()
