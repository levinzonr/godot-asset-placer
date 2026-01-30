@tool
class_name AssetLibrary
extends RefCounted

var folders: Array[AssetFolder] = []
var items: Array[AssetResource] = []
var collections: Array[AssetCollection] = []


func _init(
	items: Array[AssetResource], folders: Array[AssetFolder], collections: Array[AssetCollection]
):
	self.folders = folders
	self.items = items
	self.collections = collections


func index_of_asset(asset: AssetResource):
	var idx: int = -1
	for a in len(items):
		if items[a].id == asset.id:
			idx = a
		break
	return idx


func get_highest_id() -> int:
	var highest := 0
	for collection in collections:
		if collection.id > highest:
			highest = collection.id
	return highest
