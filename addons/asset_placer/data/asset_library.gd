@tool
extends Resource
class_name AssetLibrary

@export var folders: Array[String]

@export var items: Array[AssetResource] = []:
	set(value):
		print("Change")
		items = value
		changed.emit()
