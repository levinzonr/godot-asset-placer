@tool
extends Control


@onready var chips_container: Container = %ChipsContainer
@onready var presenter := AssetCollectionsPresenter.new()
@onready var name_text_field: LineEdit = %NameTextField
@onready var color_picker_button: ColorPickerButton= %ColorPickerButton
@onready var add_button: Button = %AddButton


func _ready():
	presenter.enable_create_button.connect(func(enabled):
		add_button.disabled = !enabled
	)
	presenter.set_color(color_picker_button.color)
	presenter.clear_text_field.connect(name_text_field.clear)
	presenter.show_collections.connect(show_collections)
	presenter.ready()
	
	add_button.pressed.connect(presenter.create_collection)
	name_text_field.text_changed.connect(presenter.set_name)
	color_picker_button.color_changed.connect(presenter.set_color)


func show_collections(items: Array[AssetCollection]):
	for child in chips_container.get_children():
		child.queue_free()
	
	for item in items:
		var chip = Button.new()
		chip.text = item.name
		chip.icon = make_circle_icon(16, item.backgroundColor)
		chips_container.add_child(chip)
		chip.pressed.connect(func(): _show_options_dialog(item))


func _show_options_dialog(collection: AssetCollection):
	var dialog = PopupMenu.new()
	var mouse_pos = EditorInterface.get_base_control().get_global_mouse_position()
	dialog.add_icon_item(EditorIconTexture2D.new("Remove"), "Delete")
	dialog.index_pressed.connect(func(i):
		presenter.delete_collection(collection)
	)
	EditorInterface.popup_dialog(dialog, Rect2i(mouse_pos, dialog.get_contents_minimum_size()))

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
