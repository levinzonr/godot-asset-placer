class_name FolderItemPresenter
extends RefCounted

var folder: AssetFolder
var synchronizer: Synchronize


func _init(target_folder: AssetFolder):
	folder = target_folder
	synchronizer = Synchronize.new()


func save():
	AssetLibraryManager.get_asset_library().update_folder(folder)


func delete():
	var lib := AssetLibraryManager.get_asset_library()
	lib.remove_folder(folder)


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
