class_name FolderItemPresenter
extends RefCounted

var folder: AssetFolder
var folder_repository: FolderRepository
var asset_repository: AssetsRepository
var synchronizer: Synchronize


func _init(target_folder: AssetFolder):
	folder = target_folder
	folder_repository = FolderRepository.instance
	asset_repository = AssetsRepository.instance
	synchronizer = Synchronize.new(folder_repository, asset_repository)


func save():
	folder_repository.update(folder)


func delete():
	folder_repository.delete(folder.path)
	for asset in asset_repository.get_all_assets():
		if asset.folder_path == folder.path:
			asset_repository.delete(asset.id)


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
