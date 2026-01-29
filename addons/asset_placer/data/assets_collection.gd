class_name AssetCollection
extends RefCounted

var name: String
var background_color: Color
var id: int


func _init(name: String, background_color: Color, id: int):
	self.background_color = background_color
	self.name = name
	self.id = id



func make_circle_icon(radius: int) -> Texture2D:
	var size = radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent background

	for y in size:
		for x in size:
			var dist = Vector2(x, y).distance_to(Vector2(radius, radius))
			if dist <= radius:
				img.set_pixel(x, y, backgroundColor)

	img.generate_mipmaps()

	var tex := ImageTexture.create_from_image(img)
	return tex
