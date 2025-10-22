extends RefCounted
class_name AssetLibraryPresenter

var library: AssetLibrary
var folder_repository: FolderRepository
var assets_repository: AssetsRepository
var synchronizer: Synchronize

var _active_collections: Array[AssetCollection] = []
var _filtered_assets: Array[AssetResource] = []
var _current_assets: Array[AssetResource]
var _current_query: String

enum EmptyType {
	Search,  Collection, All, None
}

signal assets_loaded(assets: Array[AssetResource])
signal asset_selection_change
signal show_filter_info(size: int)
signal show_sync_active(bool)
signal show_empty_view(type: EmptyType)

func _init():
	self.folder_repository = FolderRepository.instance
	self.assets_repository = AssetsRepository.instance
	self.synchronizer = Synchronize.instance
	
	

func on_ready():
	_current_assets = assets_repository.get_all_assets()
	show_filter_info.emit(0)
	assets_repository.assets_changed.connect(_filter_by_collections_and_query)
	_filter_by_collections_and_query()
	synchronizer.sync_state_change.connect(func(v):
		show_sync_active.emit(v)
	)

func add_asset_folder(path: String):
	folder_repository.add(path)
	var dir_access = DirAccess.open(path)
	for file in dir_access.get_files():
		add_asset(path + file, path)

func on_query_change(query: String):
	self._current_query = query
	_filter_by_collections_and_query()


func add_asset(path: String, folder_path: String):
	var tags: Array[int] = []
	for collection in _active_collections:
		tags.push_back(collection.id)
		
	var id = ResourceIdCompat.path_to_uid(path)
	if !id:
		push_error("Error getting id from path %s" % path)
		return
		
	var existing = assets_repository.find_by_uid(id)
	if existing:
		var new_tags: Array[int] = []
		for tag in tags:
			if tag not in existing.tags:
				new_tags.push_back(tag)
				
		existing.tags.append_array(new_tags)
		assets_repository.update(existing)
	else:
		assets_repository.add_asset(path, tags, folder_path)
	

func delete_asset(asset: AssetResource):
	assets_repository.delete(asset.id)
	_filter_by_collections_and_query()

func add_assets_or_folders(files: PackedStringArray):
	for file in files:
		if file.get_extension().is_empty():
			add_asset_folder(file)
		else:
			add_asset(file, "")
		
		_filter_by_collections_and_query()

func toggle_asset_collection(asset: AssetResource, collection: AssetCollection, add: bool):
	if add:
		asset.tags.append(collection.id)
		assets_repository.update(asset)
	else:
		asset.tags.erase(collection.id)
		assets_repository.update(asset)
	
	_filter_by_collections_and_query()

func toggle_collection_filter(collection: AssetCollection, enabled: bool):
	if enabled:
		_active_collections.push_back(collection)
	else:
		_active_collections = _active_collections.filter(func(a):
			return a.id != collection.id
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
	
	if filtered.is_empty():
		if _active_collections.is_empty() && _current_query.is_empty():
			show_empty_view.emit(EmptyType.All)
		elif not _active_collections.is_empty():
			show_empty_view.emit(EmptyType.Collection)
		else:
			show_empty_view.emit(EmptyType.Search)
	else:
		assets_loaded.emit(filtered)
		show_empty_view.emit(EmptyType.None)
		
	_filtered_assets = filtered


func sync():
	synchronizer.sync_all()
	
				
			
