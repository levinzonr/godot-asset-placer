@tool
extends Popup
class_name CollectionPicker

signal collection_selected(collection: AssetCollection, selected: bool)

@onready var collections_container: Container = %CollectionsContainer

@onready var presenter := AssetCollectionsPresenter.new()

var pre_selected: Array[AssetCollection]

func _ready():
	presenter.show_collections.connect(show_collections)
	presenter.ready()
	

func show_collections(collections: Array[AssetCollection]):
	for child in collections_container.get_children():
		child.queue_free()
	
	for item in collections:
		var chip = Chip.new()
		chip.text = item.name
		chip.toggle_mode = true
		chip.set_pressed_no_signal((pre_selected.any(func(c): return c.name == item.name)))
		chip.backgroundColor = item.backgroundColor
		collections_container.add_child(chip)
		chip.toggled.connect(func(selected):
			collection_selected.emit(item, selected)
		)


static func show_in(context: Control, selected: Array[AssetCollection], on_select: Callable):
	var picker_resource = load("res://addons/asset_placer/ui/collection_picker/collection_picker.tscn")
	var picker: CollectionPicker = picker_resource.instantiate()
	picker.collection_selected.connect(on_select)
	picker.pre_selected = selected
	var size = picker.get_contents_minimum_size()
	var global_pos = context.get_global_mouse_position() + Vector2(0, size.y)
	var position = context.get_global_mouse_position() - Vector2(size.x, size.y)
	EditorInterface.popup_dialog(picker, Rect2(position, size))
