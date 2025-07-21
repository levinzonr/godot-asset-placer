extends RefCounted
class_name AssetFolder

var path: String
var include_subfolders: bool

func _init(path: String, include_subfolders: bool = false):
	self.path = path
	self.include_subfolders = include_subfolders
