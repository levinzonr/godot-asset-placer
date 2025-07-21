extends RefCounted
class_name AssetLibraryPresenter

var library: AssetLibrary
var folder_repository: FolderRepository
var assets_repository: AssetsRepository
var synchronizer: Synchronize

signal assets_loaded(assets: Array[AssetResource])

func _init():
	self.folder_repository = FolderRepository.new()
	self.assets_repository = AssetsRepository.new()
	self.synchronizer = Synchronize.new(self.folder_repository, self.assets_repository)
	

func on_ready():
	var assets = assets_repository.get_all_assets()
	assets_loaded.emit(assets)

func add_asset_folder(path: String):
	folder_repository.add(path)

func on_query_change(query: String):
	var assets = assets_repository.get_all_assets()
	if query.is_empty():
		assets_loaded.emit(assets)
	else:
		var filtered = assets.filter(func(item: AssetResource): return item.name.contains(query))
		assets_loaded.emit(filtered)

func sync():
	synchronizer.sync_all()
				
			
