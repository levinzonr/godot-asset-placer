@tool
extends Control

@onready var button = %Button
@onready var collection_icon = %CollectionIcon
@onready var label = %Label

@onready var move_up_button = %MoveUpButton
@onready var move_down_button = %MoveDownButton


func set_collection(collection: AssetCollection):
	collection_icon.texture = load("uid://btht44hiygnmq")  # colection_circle.svg
	collection_icon.modulate = collection.background_color
	label.text = collection.name
