extends RefCounted
class_name ManageCollectionsPresenter

var assets_repository: AssetsRepository
var collections_repository: AssetCollectionRepository

signal show_active_collections(collections: Array[AssetCollection])
signal show_inactive_collections(collections: Array[AssetCollection])
signal show_assets(assets: Array[AssetResource])

var active_asset: AssetResource

func _init():
	assets_repository = AssetsRepository.instance
	collections_repository = AssetCollectionRepository.instance
	
	
func ready():
	var assets = assets_repository.get_all_assets()
	var collections = collections_repository.get_collections()
	show_assets.emit(assets)
	show_inactive_collections.emit(collections)	
	

func move_collection(collection: AssetCollection, up: bool):
	var current_index = active_asset.tags.find_custom(func(id): return id == collection.id)
	if current_index != -1:
		var new_index = current_index - 1 if up else current_index + 1
		var old_tag = active_asset.tags[new_index]
		active_asset.tags[current_index] = old_tag
		active_asset.tags[new_index] = collection.id
		assets_repository.update(active_asset)
		select_asset(active_asset)

func select_asset(asset: AssetResource):
	self.active_asset = asset
	var all_collections = collections_repository.get_collections()
	var active_collections : Array[AssetCollection] = []
	var inactive_collections : Array[AssetCollection]= []
	
	for collection in all_collections:
		if asset.belongs_to_collection(collection):
			active_collections.push_back(collection)
		else:
			inactive_collections.push_back(collection)
			
	active_collections.sort_custom(func(first, second):
		var first_order = active_asset.tags.find(first.id)
		var second_order = active_asset.tags.find(second.id)
		return first_order < second_order
	)		
			
	show_active_collections.emit(active_collections)		
	show_inactive_collections.emit(inactive_collections)

func filter_assets(query: String):
	var assets = assets_repository.get_all_assets()
	if query.is_empty():
		show_assets.emit(assets)
	else:
		var filtered_assets = assets.filter(func(asset: AssetResource): return asset.name.containsn(query))	
		show_assets.emit(filtered_assets)
			
	
func add_to_collection(collection: AssetCollection):
	if active_asset:
		active_asset.tags.push_back(collection.id)
		assets_repository.update(active_asset)
		select_asset(active_asset)


func remove_from_collection(collection: AssetCollection):
	if active_asset:
		active_asset.tags = active_asset.tags.filter(func (id): return id != collection.id)
		assets_repository.update(active_asset)
		select_asset(active_asset)
