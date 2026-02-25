@tool
class_name CollectionPicker
extends PopupMenu

signal collection_selected(collection: AssetCollection, selected: bool)

var pre_selected: Array[AssetCollection]


func _ready():
	hide_on_checkable_item_selection = false

	AssetLibraryManager.get_asset_library().collections_changed.connect(_load_collections)
	_load_collections()


func show_empty_view():
	add_item("No Collections added yet")
	index_pressed.connect(
		func(i):
			AssetPlacerDockPresenter.instance.show_tab.emit(
				AssetPlacerDockPresenter.Tab.Collections
			)
	)


func show_collections(collections: Array[AssetCollection]):
	var circle_tex := load("uid://btht44hiygnmq")  # colection_circle.svg
	for i in collections.size():
		var collection_id = collections[i].id
		var selected = pre_selected.any(func(c): return c.id == collection_id)
		add_check_item(collections[i].name)
		set_item_checked(i, selected)

		set_item_icon(i, circle_tex)
		set_item_icon_modulate(i, collections[i].background_color)

	index_pressed.connect(
		func(index):
			toggle_item_checked(index)
			collection_selected.emit(collections[index], is_item_checked(index))
	)


static func show_in(_context: Control, selected: Array[AssetCollection], on_select: Callable):
	var picker: CollectionPicker = CollectionPicker.new()
	picker.collection_selected.connect(on_select)
	picker.pre_selected = selected
	var size = picker.get_contents_minimum_size()
	var position = DisplayServer.mouse_get_position()
	EditorInterface.popup_dialog(picker, Rect2(position, size))


func _load_collections():
	var collections := AssetLibraryManager.get_asset_library().get_collections()
	if collections.is_empty():
		show_empty_view()
	else:
		show_collections(collections)