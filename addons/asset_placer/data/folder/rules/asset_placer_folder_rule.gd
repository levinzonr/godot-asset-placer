class_name AssetPlacerFolderRule
extends RefCounted


func do_file_match(_file: String) -> bool:
	return true


func do_after_asset_added(asset: AssetResource) -> AssetResource:
	return asset
