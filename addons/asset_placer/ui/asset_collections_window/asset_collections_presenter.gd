extends RefCounted
class_name AssetCollectionsPresenter

var _repository: AssetCollectionRepository
var _assets_repository: AssetsRepository

var _new_collection_name: String = ""
var _new_collection_color: Color

signal show_collections(items: Array[AssetCollection])
signal enable_create_button(enable: bool)
signal show_empty_view
signal clear_text_field()


func _init():
	self._repository = AssetCollectionRepository.new()
	self._repository.collections_changed.connect(_load_collections)
	self._assets_repository = AssetsRepository.instance

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
	var valid_name := !_new_collection_name.is_empty()
	var valid_color = _new_collection_color != null
	enable_create_button.emit(valid_color && valid_name)

func _load_collections():
	var collections := _repository.get_collections()
	if collections.size() == 0:
		show_empty_view.emit()
	else:
		show_collections.emit(collections)
	
	
func delete_collection(collection: AssetCollection):
	_repository.delete_collection(collection.name)
	for asset in _assets_repository.get_all_assets():
		var updated_tags = asset.tags.filter(func(f): return f != collection.name)
		if updated_tags != asset.tags:
			asset.tags = updated_tags
			_assets_repository.update(asset)
		
