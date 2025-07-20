@tool
extends Control
class_name AssetLibraryWindow

@onready var presenter = AssetLibraryPresenter.new()
@onready var grid_container: GridContainer = %GridContainer
@onready var preview_resource = preload("res://addons/asset_placer/ui/components/asset_resource_preview.tscn")
@onready var add_folder_button: Button = %AddFolderButton
@onready var sync_button: Button = %SyncButton
@onready var search_field: LineEdit = %SearchField

signal asset_selected(asset: AssetResource)


func _ready():
	presenter.assets_loaded.connect(show_assets)
	presenter.on_ready()
	add_folder_button.pressed.connect(show_folder_dialog)
	sync_button.pressed.connect(presenter.sync)
	search_field.text_changed.connect(presenter.on_query_change)
	
func show_assets(assets: Array[AssetResource]):
	for child in grid_container.get_children():
		child.queue_free()
	for asset in assets:
		var child: AssetResourcePreview = preview_resource.instantiate()
		child.clicked.connect(func(a): asset_selected.emit(a))
		grid_container.add_child(child)
		child.set_asset(asset)


func show_folder_dialog():
	var folder_dialog = EditorFileDialog.new()
	folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	folder_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	folder_dialog.dir_selected.connect(presenter.add_asset_folder)
	EditorInterface.popup_dialog_centered(folder_dialog)
