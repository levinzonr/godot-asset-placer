@tool
class_name AssetCollectionWindow
extends Control

var _collection_item_list_resource: PackedScene = preload(
	"res://addons/asset_placer/ui/asset_collections_window/components/collection_list_item.tscn"
)

var _new_collection_name: String = ""
var _new_collection_color: Color

@onready var name_text_field: LineEdit = %NameTextField
@onready var color_picker_button: ColorPickerButton = %ColorPickerButton
@onready var add_button: Button = %AddButton
@onready var collections_container = %CollectionsContainer
@onready var empty_view = %EmptyView


func _ready():
	AssetLibraryManager.get_asset_library().collections_changed.connect(_load_collections)
	set_color(color_picker_button.color)

	_load_collections()
	_update_state_new_collection_state()

	add_button.pressed.connect(create_collection)
	name_text_field.text_changed.connect(set_collection_name)
	color_picker_button.color_changed.connect(set_color)


func _show_empty_view():
	empty_view.show()
	collections_container.hide()


func show_collections(items: Array[AssetCollection]):
	collections_container.show()
	empty_view.hide()
	for child in collections_container.get_children():
		child.queue_free()

	for item in items:
		var list_item = _collection_item_list_resource.instantiate() as AssetCollectionListItem
		collections_container.add_child(list_item)
		list_item.delete_collection_click.connect(func(): delete_collection(item))
		list_item.edit_collection_click.connect(
			func():
				CollectionEditPopupMenu.show_popup(
					item,
					func(collection):
						AssetLibraryManager.get_asset_library().update_collection(collection)
				)
		)
		list_item.set_collection(item)


func set_color(color: Color):
	_new_collection_color = color
	_update_state_new_collection_state()


func set_collection_name(name: String):
	_new_collection_name = name
	_update_state_new_collection_state()


func create_collection():
	var lib := AssetLibraryManager.get_asset_library()
	lib.add_collection(_new_collection_name, _new_collection_color)
	name_text_field.clear()
	add_button.disabled = true


func delete_collection(collection: AssetCollection):
	AssetLibraryManager.get_asset_library().delete_collection(collection.id)


func _update_state_new_collection_state():
	var valid_name := !_new_collection_name.is_empty()
	var valid_color := _new_collection_color != null
	add_button.disabled = not (valid_color && valid_name)


func _load_collections():
	var collections := AssetLibraryManager.get_asset_library().get_collections()
	if collections.is_empty():
		_show_empty_view()
	else:
		show_collections(collections)
