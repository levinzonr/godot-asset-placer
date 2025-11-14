extends RefCounted
class_name AssetPlacerFolderRule


func do_file_match(file: String) -> bool:
	return true
	

func do_after_asset_added(asset: AssetResource) -> AssetResource:
	return asset	