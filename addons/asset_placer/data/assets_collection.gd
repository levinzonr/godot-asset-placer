extends RefCounted
class_name AssetCollection

var name: String
var backgroundColor: Color


func _init(name: String, backgroundColor: Color):
	self.backgroundColor = backgroundColor
	self.name = name
