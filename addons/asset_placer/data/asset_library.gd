@tool
extends RefCounted
class_name AssetLibrary

var folders: Array[AssetFolder] = []
var items: Array[AssetResource] = []
var collections: Array[AssetCollection] = []


func _init(items: Array[AssetResource], folders: Array[AssetFolder], collections: Array[AssetCollection]):
	self.folders = folders
	self.items = items
	self.collections = collections



func index_of_asset(asset: AssetResource):
	return items.find_custom(func(a): return a.id == asset.id)
