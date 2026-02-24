@tool
class_name FoldersWindow
extends Control

@onready var v_box_container = %VBoxContainer
@onready var add_folder_button: Button = %AddFolderButton
@onready var folder_res = preload("res://addons/asset_placer/ui/folders_window/folder_view.tscn")


func _ready():
	var lib := AssetLibraryManager.get_asset_library()
	lib.folders_changed.connect(show_folders)
	show_folders()

	add_folder_button.pressed.connect(func(): show_folder_dialog())


func _can_drop_data(_at_position, data):
	if data is Dictionary:
		var type = data["type"]
		var dirs = type == "files_and_dirs"
		return dirs and data.has("files")
	return false


func _drop_data(_at_position, data):
	var dirs: PackedStringArray = data["files"]
	add_folders(dirs)


func show_folders():
	for child in v_box_container.get_children():
		child.queue_free()

	for folder in AssetLibraryManager.get_asset_library().get_folders():
		var instance: FolderView = folder_res.instantiate()
		v_box_container.add_child(instance)
		instance.set_folder(folder)
		instance.folder_delete_clicked.connect(func(): delete_folder(folder))
		instance.folder_sync_clicked.connect(func(): Synchronize.instance.sync_folder(folder))
		instance.folder_include_subfloders_change.connect(
			func(include): include_subfolders(include, folder)
		)


func show_folder_dialog():
	var folder_dialog := EditorFileDialog.new()
	folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	folder_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	folder_dialog.dir_selected.connect(add_folder)
	EditorInterface.popup_dialog_centered(folder_dialog)


func add_folder(folder_path: String):
	if folder_path.get_extension().is_empty():
		AssetLibraryManager.get_asset_library().add_folder(folder_path)


func add_folders(folders: PackedStringArray):
	for folder in folders:
		add_folder(folder)


func delete_folder(folder: AssetFolder):
	var lib := AssetLibraryManager.get_asset_library()
	lib.remove_folder_by_path(folder.path)

	# TODO SHould be in asset library.
	for asset in lib.get_assets():
		if asset.folder_path == folder.path:
			lib.remove_asset_by_id(asset.id)


# TODO Should also update assets no?
func include_subfolders(include: bool, folder: AssetFolder):
	folder.include_subfolders = include
	AssetLibraryManager.get_asset_library().update_folder(folder)
