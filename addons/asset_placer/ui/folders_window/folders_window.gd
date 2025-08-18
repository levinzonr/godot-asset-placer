@tool
extends Control
class_name FoldersWindow

@onready var v_box_container = %VBoxContainer
@onready var  presenter: FolderPresenter = FolderPresenter.new()
@onready var add_folder_button: Button = %AddFolderButton

@onready var folder_res = preload("res://addons/asset_placer/ui/folders_window/folder_view.tscn")


func _ready():
	presenter.folders_loaded.connect(show_folders)
	presenter._ready()
	
	add_folder_button.pressed.connect(func():
		show_folder_dialog()
	)

func _can_drop_data(at_position, data):
	if data is Dictionary:
		var type = data["type"]
		var dirs = type == "files_and_dirs"
		return dirs and data.has("files")
	return false	
	
func _drop_data(at_position, data):
	var dirs: PackedStringArray = data["files"]
	presenter.add_folders(dirs)

func show_folders(folders: Array[AssetFolder]):
	for child in v_box_container.get_children():
		child.queue_free()
		
	for folder in folders:
		var instance: FolderView = folder_res.instantiate()
		v_box_container.add_child(instance)
		instance.set_folder(folder)
		instance.folder_delete_clicked.connect(func():
			presenter.delete_folder(folder)
		)
		instance.folder_include_subfloders_change.connect(func(include):
			presenter.include_subfolders(include, folder)
		)
		instance.folder_sync_clicked.connect(func():
			presenter.sync_folder(folder)
		)
		
		
func show_folder_dialog():
	var folder_dialog = EditorFileDialog.new()
	folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	folder_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	folder_dialog.dir_selected.connect(presenter.add_folder)
	EditorInterface.popup_dialog_centered(folder_dialog)
