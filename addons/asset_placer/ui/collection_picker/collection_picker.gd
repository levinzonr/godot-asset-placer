@tool
extends Popup
class_name CollectionPicker

signal collection_selected(collection: AssetCollection)

@onready var collections_container: Container = %CollectionsContainer

@onready var presenter := AssetCollectionsPresenter.new()

func _ready():
	presenter.show_collections.connect(show_collections)
	presenter.ready()
	

func show_collections(collections: Array[AssetCollection]):
	for child in collections_container.get_children():
		child.queue_free()
	
	for item in collections:
		var chip = Chip.new()
		chip.text = item.name
		chip.backgroundColor = item.backgroundColor
		collections_container.add_child(chip)
		chip.pressed.connect(func():
			collection_selected.emit(item)
			queue_free()
		)
