@tool
extends Control
class_name FolderView

@onready var path_label: Label = %PathLabel
@onready var subfolders_checkbox: CheckBox = %SubfoldersCheckbox
@onready var delete_button: Button = %DeleteButton
@onready var sync_button: Button = %SyncButton

signal folder_delete_clicked
signal folder_sync_clicked
signal folder_include_subfloders_change(bool)

func _ready():
	delete_button.pressed.connect(func():
		folder_delete_clicked.emit()
	)
	
	sync_button.pressed.connect(func():
		folder_sync_clicked.emit()
	)
	
	subfolders_checkbox.toggled.connect(func(toggled):
		folder_include_subfloders_change.emit(toggled)
	)

func set_folder(folder: AssetFolder):
	path_label.text = folder.path
	subfolders_checkbox.button_pressed = folder.include_subfolders
