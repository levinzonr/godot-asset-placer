@tool
extends Control

@onready var button = %Button
@onready var collection_icon = %CollectionIcon
@onready var label = %Label

@onready var move_up_button = %MoveUpButton
@onready var move_down_button = %MoveDownButton


func set_collection(collection: AssetCollection):
	collection_icon.texture = collection.make_circle_icon(24)
	label.text = collection.name
