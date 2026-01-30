class_name ManageCollectionsPresenter
extends RefCounted

signal show_active_collections(collections: Array[AssetCollection])
signal show_partial_collections(collections: Array[AssetCollection])
signal show_inactive_collections(collections: Array[AssetCollection])
signal show_assets(assets: Array[AssetResource])

var assets_repository: AssetsRepository
var collections_repository: AssetCollectionRepository
var selected_assets: Array[AssetResource] = []


func _init():
	assets_repository = AssetsRepository.instance
	collections_repository = AssetCollectionRepository.instance


func ready():
	var assets = assets_repository.get_all_assets()
	var collections = collections_repository.get_collections()
	show_assets.emit(assets)
	show_inactive_collections.emit(collections)


func set_primary_collection(collection: AssetCollection):
	for asset in selected_assets:
		var current_index = asset.tags.find(collection.id)
		if current_index > 0:
			# Move to front
			asset.tags.remove_at(current_index)
			asset.tags.insert(0, collection.id)
			assets_repository.update(asset)
	select_assets(selected_assets)


func select_assets(assets: Array[AssetResource]):
	self.selected_assets = assets
	var all_collections = collections_repository.get_collections()
	var full_collections: Array[AssetCollection] = []
	var partial_collections: Array[AssetCollection] = []
	var inactive_collections: Array[AssetCollection] = []

	if assets.is_empty():
		show_active_collections.emit(full_collections)
		show_partial_collections.emit(partial_collections)
		show_inactive_collections.emit(all_collections)
		return

	for collection in all_collections:
		var count = 0
		for asset in assets:
			if asset.belongs_to_collection(collection):
				count += 1

		if count == assets.size():
			full_collections.push_back(collection)
		elif count > 0:
			partial_collections.push_back(collection)
		else:
			inactive_collections.push_back(collection)

	# Sort full collections by order in first selected asset's tags
	if not assets.is_empty():
		var first_asset = assets[0]
		full_collections.sort_custom(
			func(a, b):
				var a_order = first_asset.tags.find(a.id)
				var b_order = first_asset.tags.find(b.id)
				if a_order == -1:
					a_order = 9999
				if b_order == -1:
					b_order = 9999
				return a_order < b_order
		)

	show_active_collections.emit(full_collections)
	show_partial_collections.emit(partial_collections)
	show_inactive_collections.emit(inactive_collections)


func filter_assets(query: String):
	var assets = assets_repository.get_all_assets()
	if query.is_empty():
		show_assets.emit(assets)
	else:
		var filtered_assets = assets.filter(
			func(asset: AssetResource): return asset.name.containsn(query)
		)
		show_assets.emit(filtered_assets)


func add_to_collection(collection: AssetCollection):
	for asset in selected_assets:
		if not asset.tags.has(collection.id):
			asset.tags.push_back(collection.id)
			assets_repository.update(asset)
	select_assets(selected_assets)


func remove_from_collection(collection: AssetCollection):
	for asset in selected_assets:
		asset.tags = asset.tags.filter(func(id): return id != collection.id)
		assets_repository.update(asset)
	select_assets(selected_assets)
