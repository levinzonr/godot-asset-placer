@tool
extends Control

@onready var button = %Button
@onready var collection_icon = %CollectionIcon
@onready var label = %Label

@onready var move_up_button = %MoveUpButton
@onready var move_down_button = %MoveDownButton


func set_collection(collection: AssetCollection, is_partial: bool = false):
	collection_icon.texture = load("uid://btht44hiygnmq")
	collection_icon.modulate = collection.background_color
	if is_partial:
		label.text = collection.name + " (partial)"
		collection_icon.modulate.a = 0.5
	else:
		label.text = collection.name
