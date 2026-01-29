class_name AddToCollectionRule
extends AssetPlacerFolderRule

var collections: Array[int]


func _init(collections: Array[int]):
	self.collections = collections


func do_after_asset_added(asset: AssetResource) -> AssetResource:
	var tags = asset.tags
	for collection_id in collections:
		if not tags.has(collection_id):
			tags.push_back(collection_id)
	asset.tags = tags
	return asset
