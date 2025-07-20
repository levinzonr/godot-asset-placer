@tool
extends Control
class_name FoldersWindow

@onready var v_box_container = %VBoxContainer
@onready var  presenter: FolderPresenter = FolderPresenter.new()
@onready var add_folder_button: Button = %AddFolderButton

@onready var folder_res = preload("uid://d7ay5upbgnx0")

func _ready():
	presenter.folders_loaded.connect(show_folders)
	presenter._ready()
	
	add_folder_button.pressed.connect(func():
		show_folder_dialog()
	)
	

func show_folders(folders: Array[String]):
	print("Show filders")
	for child in v_box_container.get_children():
		child.queue_free()
		
	for folder in folders:
		var instance: FolderView = folder_res.instantiate()
		v_box_container.add_child(instance)
		instance.set_folder(folder)
		instance.folder_delete_clicked.connect(func():
			presenter.delete_folder(folder)
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
