@tool
extends PopupMenu
class_name CollectionPicker

signal collection_selected(collection: AssetCollection, selected: bool)

@onready var presenter := AssetCollectionsPresenter.new()

var pre_selected: Array[AssetCollection]

func _ready():
	hide_on_checkable_item_selection = false
	presenter.show_collections.connect(show_collections)
	presenter.show_empty_view.connect(show_empty_view)
	presenter.ready()
	

func show_empty_view():
	add_item("No Collections added yet")
	index_pressed.connect(func(i):
		AssetPlacerDockPresenter.instance.show_tab.emit(
			AssetPlacerDockPresenter.Tab.Collections
		)
	)

func show_collections(collections: Array[AssetCollection]):
	for i in collections.size():
		var collection_id = collections[i].id
		var selected = pre_selected.any(func(c): return c.id == collection_id)
		add_check_item(collections[i].name)
		set_item_checked(i, selected)
		set_item_icon(i, make_circle_icon(16, collections[i].backgroundColor))
	
	index_pressed.connect(func(index):
		toggle_item_checked(index)
		collection_selected.emit(collections[index], is_item_checked(index))
	)
	
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

static func show_in(context: Control, selected: Array[AssetCollection], on_select: Callable):
	var picker: CollectionPicker = CollectionPicker.new()
	picker.collection_selected.connect(on_select)
	picker.pre_selected = selected
	var size = picker.get_contents_minimum_size()
	var position = DisplayServer.mouse_get_position()
	EditorInterface.popup_dialog(picker, Rect2(position, size))
