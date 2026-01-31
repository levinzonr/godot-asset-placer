@tool
extends PanelContainer

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


func set_primary(is_primary: bool):
	if is_primary:
		label.add_theme_color_override("font_color", Color.YELLOW)
		move_up_button.hide()
	else:
		move_up_button.theme_type_variation = &"FlatButton"
