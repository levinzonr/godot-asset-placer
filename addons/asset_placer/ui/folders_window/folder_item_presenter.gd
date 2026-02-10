class_name FolderItemPresenter
extends RefCounted

var folder: AssetFolder
var folder_repository: FolderRepository
var synchronizer: Synchronize


func _init(target_folder: AssetFolder):
	folder = target_folder
	folder_repository = FolderRepository.instance
	synchronizer = Synchronize.new(folder_repository)


func save():
	folder_repository.update(folder)


func delete_folder():
	var lib := AssetLibraryManager.get_asset_library()
	folder_repository.delete(folder.path)
	for asset in lib.get_assets():
		if asset.folder_path == folder.path:
			lib.remove_asset(asset)


func sync():
	synchronizer.sync_folder(folder)


func set_include_subfolders(include: bool):
	folder.include_subfolders = include
	save()


func add_rule(rule: AssetPlacerFolderRule):
	folder.add_rule(rule)
	save()


func remove_rule_at(index: int):
	folder.remove_rule_at(index)
	save()
