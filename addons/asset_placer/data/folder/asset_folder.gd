extends RefCounted
class_name AssetFolder

var path: String
var include_subfolders: bool
var rules: Array[AssetPlacerFolderRule]

func _init(path: String, include_subfolders: bool = false, rules: Array[AssetPlacerFolderRule] = []):
	self.path = path
	self.include_subfolders = include_subfolders
	self.rules = rules
