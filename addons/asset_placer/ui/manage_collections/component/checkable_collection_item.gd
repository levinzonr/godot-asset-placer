@tool
extends PanelContainer

signal action_pressed
signal set_primary_pressed

const CIRCLE_ICON = preload(
	"res://addons/asset_placer/ui/asset_collections_window/components/collection_circle.svg"
)

@onready var _button: Button = %Button
@onready var _collection_icon: TextureRect = %CollectionIcon
@onready var _label: Label = %Label
@onready var _favorite_button: Button = %MoveUpButton
@onready var _move_down_button: Button = %MoveDownButton

var _collection_color: Color


func _ready():
	_button.pressed.connect(func(): action_pressed.emit())
	_favorite_button.pressed.connect(func(): set_primary_pressed.emit())


func configure_as_assigned(
	collection: AssetCollection, is_partial: bool, is_primary: bool, batch_count: int = 1
):
	_set_collection_info(collection, is_partial)
	
	_button.icon = EditorIconTexture2D.new("Clear")
	if batch_count > 1:
		_button.text = "Unasign from %d assets" % batch_count
	else:
		_button.text = "Unasign"
	
	_move_down_button.hide()
	
	if is_partial:
		_favorite_button.show()
	else:
		_favorite_button.icon = EditorIconTexture2D.new("Favorites")
		_favorite_button.theme_type_variation = &"FlatButton"
		
		if batch_count > 1:
			_favorite_button.tooltip_text = "Set as primary for %d assets" % batch_count
			_favorite_button.show()
		else:
			_favorite_button.tooltip_text = "Set as Primary"
		_apply_primary_state(is_primary)


func configure_as_available(collection: AssetCollection, batch_count: int = 1):
	_set_collection_info(collection, false)
	_favorite_button.hide()
	_button.icon = EditorIconTexture2D.new("Add")
	if batch_count > 1:
		_button.text = "Asign to %d assets" % batch_count
	else:
		_button.text = "Asign"
	
	_move_down_button.hide()


func _set_collection_info(collection: AssetCollection, is_partial: bool):
	_collection_color = collection.background_color
	_collection_icon.texture = CIRCLE_ICON
	_collection_icon.modulate = _collection_color
	_collection_icon.size = Vector2(32, 32)
	
	if is_partial:
		_label.text = collection.name + " (partial)"
		_collection_icon.modulate.a = 0.5
	else:
		_label.text = collection.name
	
	_label.remove_theme_color_override("font_color")


func _apply_primary_state(is_primary: bool):
	if is_primary:
		_collection_icon.texture = EditorIconTexture2D.new("Favorites")
		_collection_icon.modulate = _collection_color
		_collection_icon.size = Vector2(64, 64)
		_label.add_theme_color_override("font_color", Color.YELLOW)
