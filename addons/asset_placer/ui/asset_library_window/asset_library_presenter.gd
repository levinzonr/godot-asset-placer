extends RefCounted
class_name AssetLibraryPresenter

var library: AssetLibrary
var folder_repository: FolderRepository
var assets_repository: AssetsRepository
var synchronizer: Synchronize

var _active_collections: Array[AssetCollection] = []
var _current_assets: Array[AssetResource]
var _current_query: String

signal assets_loaded(assets: Array[AssetResource])
signal asset_selection_change
signal show_filter_info(size: int)
signal show_sync_active(bool)

func _init():
	self.folder_repository = FolderRepository.instance
	self.assets_repository = AssetsRepository.instance
	self.synchronizer = Synchronize.instance
	
	

func on_ready():
	_current_assets = assets_repository.get_all_assets()
	show_filter_info.emit(0)
	assets_repository.assets_changed.connect(_filter_by_collections_and_query)
	assets_loaded.emit(_current_assets)
	synchronizer.sync_state_change.connect(func(v):
		show_sync_active.emit(v)
	)

func add_asset_folder(path: String):
	folder_repository.add(path)

func on_query_change(query: String):
	self._current_query = query
	_filter_by_collections_and_query()

func add_asset(path: String):
	var tags: Array[String] = []
	for collection in _active_collections:
		tags.push_back(collection.name)
	assets_repository.add_asset(path, tags)
	

func delete_asset(asset: AssetResource):
	assets_repository.delete(asset.id)
	_filter_by_collections_and_query()

func add_assets_or_folders(files: PackedStringArray):
	for file in files:
		var extension = file.get_extension()
		if extension == "":
			add_asset_folder(file)
		else:
			add_asset(file)
		
		_filter_by_collections_and_query()

func toggle_asset_collection(asset: AssetResource, collection: AssetCollection, add: bool):
	if add:
		asset.tags.append(collection.name)
		assets_repository.update(asset)
	else:
		asset.tags.erase(collection.name)
		assets_repository.update(asset)
	
	_filter_by_collections_and_query()

func toggle_collection_filter(collection: AssetCollection, enabled: bool):
	if enabled:
		_active_collections.push_back(collection)
	else:
		_active_collections = _active_collections.filter(func(a):
			return a.name != collection.name
		)
	show_filter_info.emit(_active_collections.size())
	_filter_by_collections_and_query()
	


func _filter_by_collections_and_query():
	var all = assets_repository.get_all_assets()
	var filtered: Array[AssetResource] = []
	
	for asset in all:
		var matches_query = asset.name.containsn(_current_query) || _current_query.is_empty()
		var belongs_to_collection = asset.belongs_to_some_collection(_active_collections) || _active_collections.is_empty()
		
		if matches_query and belongs_to_collection:
			filtered.push_back(asset)
			
	assets_loaded.emit(filtered)


func sync():
	synchronizer.sync_all()
	
				
			
