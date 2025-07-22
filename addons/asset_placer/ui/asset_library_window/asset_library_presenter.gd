extends RefCounted
class_name AssetLibraryPresenter

var library: AssetLibrary
var folder_repository: FolderRepository
var assets_repository: AssetsRepository
var synchronizer: Synchronize

var _current_collection_filter: AssetCollection
var _current_assets: Array[AssetResource]

signal assets_loaded(assets: Array[AssetResource])

func _init():
	self.folder_repository = FolderRepository.new()
	self.assets_repository = AssetsRepository.new()
	self.synchronizer = Synchronize.new(self.folder_repository, self.assets_repository)
	

func on_ready():
	_current_assets = assets_repository.get_all_assets()
	assets_loaded.emit(_current_assets)

func add_asset_folder(path: String):
	folder_repository.add(path)

func on_query_change(query: String):
	if query.is_empty():
		assets_loaded.emit(_current_assets)
	else:
		var filtered = _current_assets.filter(func(item: AssetResource): return item.name.containsn(query))
		assets_loaded.emit(filtered)


func add_asset_to_collection(asset: AssetResource, collection: AssetCollection):
	asset.tags.append(collection.name)
	assets_repository.update(asset)
	on_ready()
	

func filter_by_collection(collection: AssetCollection):
	var all = assets_repository.get_all_assets()
	
	
	if _current_collection_filter and _current_collection_filter.name == collection.name:
		_current_collection_filter = null
		_current_assets = all
		assets_loaded.emit(all)
		return
	
	_current_collection_filter = collection
	var filtered: Array[AssetResource] = []
	for asset in all:
		if asset.tags.has(collection.name):
			filtered.append(asset)
	
	_current_assets = filtered
	assets_loaded.emit(filtered)



func sync():
	synchronizer.sync_all()
				
			
