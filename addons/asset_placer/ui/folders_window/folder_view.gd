@tool
class_name FolderView
extends Control

signal folder_delete_clicked
signal folder_sync_clicked
signal folder_include_subfloders_change(bool)

var asset_folder: AssetFolder

@onready var path_label: Label = %PathLabel
@onready var subfolders_checkbox: CheckBox = %SubfoldersCheckbox
@onready var delete_button: Button = %DeleteButton
@onready var sync_button: Button = %SyncButton


func _ready():
	delete_button.pressed.connect(func(): folder_delete_clicked.emit())

	sync_button.pressed.connect(func(): folder_sync_clicked.emit())

	subfolders_checkbox.toggled.connect(
		func(toggled): folder_include_subfloders_change.emit(toggled)
	)

	if is_instance_valid(asset_folder):
		set_folder(asset_folder)


func set_folder(folder: AssetFolder):
	asset_folder = folder
	if is_node_ready():
		path_label.text = folder.path
		subfolders_checkbox.button_pressed = folder.include_subfolders
