extends RefCounted
class_name AssetCollectionsPresenter

var _repository: AssetCollectionRepository

var _new_collection_name: String = ""
var _new_collection_color: Color

signal show_collections(items: Array[AssetCollection])
signal enable_create_button(enable: bool)
signal clear_text_field()


func _init():
	self._repository = AssetCollectionRepository.new()
	self._repository.collections_changed.connect(_load_collections)

func ready():
	_load_collections()
	_update_state_new_collection_state()

func set_color(color: Color):
	_new_collection_color = color
	_update_state_new_collection_state()

func set_name(name: String):
	_new_collection_name = name
	_update_state_new_collection_state()

func create_collection():
	var collection = AssetCollection.new(_new_collection_name, _new_collection_color)
	_repository.add_collection(collection)
	clear_text_field.emit()
	enable_create_button.emit(false)

func _update_state_new_collection_state():
	var valid_name = !_new_collection_name.is_empty()
	var valid_color = _new_collection_color != null
	enable_create_button.emit(valid_color && valid_name)

func _load_collections():
	var collections = _repository.get_collections()
	show_collections.emit(collections)
