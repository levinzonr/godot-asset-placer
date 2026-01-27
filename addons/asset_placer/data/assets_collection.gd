class_name AssetCollection
extends RefCounted

var name: String
var background_color: Color
var id: int


func _init(name: String, background_color: Color, id: int):
	self.background_color = background_color
	self.name = name
	self.id = id
