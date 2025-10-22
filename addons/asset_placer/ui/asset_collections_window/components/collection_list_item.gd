@tool
extends Control
class_name AssetCollectionListItem

@onready var delete_button:  Button = %DeleteButton
@onready var edit_button: Button = %EditButton
@onready var texture_rect: TextureRect = %TextureRect
@onready var name_label: Label = %NameLabel

signal delete_collection_click
signal edit_collection_click

func _ready():
	delete_button.pressed.connect(delete_collection_click.emit)
	edit_button.pressed.connect(edit_collection_click.emit)

func set_collection(collection: AssetCollection):
	name_label.text = collection.name
	texture_rect.texture = make_circle_icon(32, collection.backgroundColor)
	
	

func make_circle_icon(radius: int, color: Color) -> Texture2D:
	var size = radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent background

	for y in size:
		for x in size:
			var dist = Vector2(x, y).distance_to(Vector2(radius, radius))
			if dist <= radius:
				img.set_pixel(x, y, color)

	img.generate_mipmaps()

	var tex := ImageTexture.create_from_image(img)
	return tex
