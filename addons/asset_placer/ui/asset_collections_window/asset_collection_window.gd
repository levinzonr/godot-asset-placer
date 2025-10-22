@tool
extends Control


@onready var presenter := AssetCollectionsPresenter.new()
@onready var name_text_field: LineEdit = %NameTextField
@onready var color_picker_button: ColorPickerButton= %ColorPickerButton
@onready var add_button: Button = %AddButton
@onready var collections_container = %CollectionsContainer
@onready var empty_view = %EmptyView


var _collection_item_list_resource: PackedScene = preload("res://addons/asset_placer/ui/asset_collections_window/components/collection_list_item.tscn")

func _ready():
	presenter.enable_create_button.connect(func(enabled):
		add_button.disabled = !enabled
	)
	presenter.set_color(color_picker_button.color)
	presenter.clear_text_field.connect(name_text_field.clear)
	presenter.show_collections.connect(show_collections)
	presenter.show_empty_view.connect(_show_empty_view)
	presenter.ready()
	
	add_button.pressed.connect(presenter.create_collection)
	name_text_field.text_changed.connect(presenter.set_name)
	color_picker_button.color_changed.connect(presenter.set_color)


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
		list_item.delete_collection_click.connect(func():
			presenter.delete_collection(item)
		)
		list_item.edit_collection_click.connect(func():
			CollectionEditPopupMenu.show_popup(item, func(collection):
				presenter._repository.update_collection(collection)
			)
		)
		list_item.set_collection(item)
		
