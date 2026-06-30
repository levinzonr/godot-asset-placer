class_name BrushDecalBuilder
extends Object

static var _brush_texture: Texture2D

static func build_decal() -> Decal:
	var decal = Decal.new()
	decal.texture_albedo = _get_brush_texture()
	decal.albedo_mix = 1.0
	return decal

static func _get_brush_texture() -> Texture2D:
	if _brush_texture != null:
		return _brush_texture
	var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center = Vector2(64, 64)
	for x in range(128):
		for y in range(128):
			var dist = center.distance_to(Vector2(x, y))
			if dist > 60 and dist < 64:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	_brush_texture = ImageTexture.create_from_image(img)
	return _brush_texture
