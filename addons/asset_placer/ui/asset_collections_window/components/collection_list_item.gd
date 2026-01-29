@tool
class_name AssetCollectionListItem
extends Control

signal delete_collection_click
signal edit_collection_click

@onready var delete_button: Button = %DeleteButton
@onready var edit_button: Button = %EditButton
@onready var texture_rect: TextureRect = %TextureRect
@onready var name_label: Label = %NameLabel


func _ready():
	delete_button.pressed.connect(delete_collection_click.emit)
	edit_button.pressed.connect(edit_collection_click.emit)


func set_collection(collection: AssetCollection):
	name_label.text = collection.name
	texture_rect.modulate = collection.background_color
