@tool
extends RefCounted
class_name AssetLibrary

var folders: Array[AssetFolder] = []
var items: Array[AssetResource] = []


func _init(items: Array[AssetResource], folders: Array[AssetFolder]):
	self.folders = folders
	self.items = items
