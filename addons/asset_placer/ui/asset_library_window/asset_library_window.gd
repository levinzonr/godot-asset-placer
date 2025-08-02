@tool
extends Control
class_name AssetLibraryWindow

@onready var presenter = AssetLibraryPresenter.new()
@onready var grid_container: GridContainer = %GridContainer
@onready var preview_resource = preload("res://addons/asset_placer/ui/components/asset_resource_preview.tscn")
@onready var add_folder_button: Button = %AddFolderButton
@onready var sync_button: Button = %SyncButton
@onready var search_field: LineEdit = %SearchField
@onready var filter_button: Button = %FilterButton

var picker_resource = preload("res://addons/asset_placer/ui/collection_picker/collection_picker.tscn")

signal asset_selected(asset: AssetResource)


func _ready():
	presenter.assets_loaded.connect(show_assets)
	AssetPlacerPresenter._instance.asset_selected.connect(set_selected_asset)
	AssetPlacerPresenter._instance.asset_deselcted.connect(clear_selected_asset)
	presenter.on_ready()
	add_folder_button.pressed.connect(show_folder_dialog)
	sync_button.pressed.connect(presenter.sync)
	search_field.text_changed.connect(presenter.on_query_change)
	
	filter_button.pressed.connect(func ():
		var picker: CollectionPicker = picker_resource.instantiate()
		picker.collection_selected.connect(presenter.filter_by_collection)
		var global_pos = filter_button.get_screen_position() + Vector2(0, filter_button.size.y)
		var size = Vector2i(500, 500)
		var position = filter_button.get_screen_position() - Vector2(size.x, size.y)
		EditorInterface.popup_dialog(picker, Rect2(position, size))
	)
	
func show_assets(assets: Array[AssetResource]):
	for child in grid_container.get_children():
		child.queue_free()
	for asset in assets:
		var child: AssetResourcePreview = preview_resource.instantiate()
		child.left_clicked.connect(AssetPlacerPresenter._instance.select_asset)
		child.right_clicked.connect(show_asset_menu)
		child.set_meta("id", asset.id)
		grid_container.add_child(child)
		child.set_asset(asset)

func show_asset_menu(asset: AssetResource):
	var options_menu := PopupMenu.new()
	var mouse_pos = EditorInterface.get_base_control().get_global_mouse_position()
	options_menu.add_item("Add to collection")
	options_menu.index_pressed.connect(func(index):
		var collection_picker: CollectionPicker = load("res://addons/asset_placer/ui/collection_picker/collection_picker.tscn").instantiate()
		collection_picker.collection_selected.connect(func(collection):
			presenter.add_asset_to_collection(asset, collection)
			
		)
		EditorInterface.popup_dialog(collection_picker, Rect2i(mouse_pos, Vector2(500, 500)))
	)
	EditorInterface.popup_dialog(options_menu, Rect2(mouse_pos, options_menu.get_contents_minimum_size()))

func show_folder_dialog():
	var folder_dialog = EditorFileDialog.new()
	folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	folder_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	folder_dialog.dir_selected.connect(presenter.add_asset_folder)
	EditorInterface.popup_dialog_centered(folder_dialog)


func clear_selected_asset():
	for child in grid_container.get_children():
		if child is Button:
			child.set_pressed_no_signal(false)

func set_selected_asset(asset: AssetResource):
	for child in grid_container.get_children():
		if child is Button:
			child.set_pressed_no_signal(child.get_meta("id") == asset.id)
