@tool
extends Control
class_name AssetLibraryWindow

@onready var presenter = AssetLibraryPresenter.new()
@onready var folder_presenter = FolderPresenter.new()

@onready var placer_presenter := AssetPlacerPresenter._instance
@onready var grid_container: Container = %GridContainer
@onready var preview_resource = preload("res://addons/asset_placer/ui/components/asset_resource_preview.tscn")
@onready var add_folder_button: Button = %AddFolderButton
@onready var search_field: LineEdit = %SearchField
@onready var filter_button: Button = %FilterButton
@onready var filters_label: Label = %FiltersLabel
@onready var reload_button: Button = %ReloadButton
@onready var progress_bar = %ProgressBar
@onready var empty_content = %EmptyContent
@onready var main_content = %MainContent
@onready var empty_collection_content = %EmptyCollectionContent
@onready var empty_collection_view_add_folder_btn: Button = %EmptyCollectionViewAddFolderBtn
@onready var scroll_container = %ScrollContainer
@onready var empty_search_content = %EmptySearchContent
@onready var empty_view_add_folder_btn = %EmptyViewAddFolderBtn

signal asset_selected(asset: AssetResource)


func _ready():
	presenter.assets_loaded.connect(show_assets)
	presenter.show_filter_info.connect(show_filter_info)
	presenter.show_sync_active.connect(show_sync_in_progress)
	AssetPlacerPresenter._instance.asset_selected.connect(set_selected_asset)
	AssetPlacerPresenter._instance.asset_deselected.connect(clear_selected_asset)
	empty_collection_view_add_folder_btn.pressed.connect(show_folder_dialog)
	empty_view_add_folder_btn.pressed.connect(show_folder_dialog)
	presenter.show_empty_view.connect(show_empty_view)

	presenter.on_ready()
	add_folder_button.pressed.connect(show_folder_dialog)
	search_field.text_changed.connect(presenter.on_query_change)
	reload_button.pressed.connect(presenter.sync)
	filter_button.pressed.connect(func ():
		CollectionPicker.show_in(filter_button, presenter._active_collections, presenter.toggle_collection_filter)
	)
	
	

	
func show_assets(assets: Array[AssetResource]):
	placer_presenter.current_assets = assets
	empty_collection_content.hide()
	scroll_container.show()
	for child in grid_container.get_children():
		child.queue_free()
	for asset in assets:
		var child: AssetResourcePreview = preview_resource.instantiate()
		child.left_clicked.connect(AssetPlacerPresenter._instance.toggle_asset)
		child.right_clicked.connect(func(asset):
			show_asset_menu(asset, child)
		)
		child.set_meta("id", asset.id)
		grid_container.add_child(child)
		child.set_asset(asset)

func show_asset_menu(asset: AssetResource, control: Control):
	var options_menu := PopupMenu.new()
	var mouse_pos = DisplayServer.mouse_get_position()
	options_menu.add_icon_item(EditorIconTexture2D.new("Groups"), "Manage collections")
	options_menu.add_icon_item(EditorIconTexture2D.new("File"), "Open")
	options_menu.add_icon_item(EditorIconTexture2D.new("Remove"), "Remove")
	options_menu.index_pressed.connect(func(index):
		match index:
			0: CollectionPicker.show_in(control, asset.shallow_collections, func(collection, add):
				presenter.toggle_asset_collection(asset, collection, add)
			)
			1: 
				EditorInterface.open_scene_from_path(asset.scene.resource_path)
				EditorInterface.set_main_screen_editor("3D")
			2: 
				if placer_presenter._selected_asset == asset:
					placer_presenter.clear_selection()
				presenter.delete_asset(asset)
			_: pass
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
			
func _can_drop_data(at_position, data):
	if data is Dictionary:
		var type = data["type"]
		var files_or_dirs = type == "files_and_dirs" || type == "files"
		return files_or_dirs and data.has("files")
	return false	
	
func _drop_data(at_position, data):
	var dirs: PackedStringArray = data["files"]
	presenter.add_assets_or_folders(dirs)

func show_filter_info(size: int):
	if size == 0:
		filters_label.hide()
	else:
		filters_label.show()
		filters_label.text = str(size)	

func set_selected_asset(asset: AssetResource):
	for child in grid_container.get_children():
		if child is Button:
			child.set_pressed_no_signal(child.get_meta("id") == asset.id)



	
func show_empty_view(type: AssetLibraryPresenter.EmptyType):
	match type:
		AssetLibraryPresenter.EmptyType.Search:
			show_empty_search_content()
		AssetLibraryPresenter.EmptyType.Collection:
			show_empty_collection_view()
		AssetLibraryPresenter.EmptyType.All:
			show_onboarding()
		AssetLibraryPresenter.EmptyType.None:
			show_main_content()

func show_main_content():
	main_content.show()
	empty_content.hide()
	scroll_container.show()
	empty_collection_content.hide()
	empty_search_content.hide()
	
func show_onboarding():
	main_content.hide()
	empty_collection_content.hide()	
	empty_search_content.hide()
	empty_content.show()
			
func show_empty_collection_view():
	main_content.show()
	scroll_container.hide()
	empty_collection_content.hide()
	empty_collection_content.show()
	empty_content.hide()
	
func show_empty_search_content():
	main_content.show()
	scroll_container.hide()
	empty_collection_content.hide()	
	empty_search_content.show()			

func show_sync_in_progress(active: bool):
	if active:
		reload_button.hide()
		progress_bar.show()
	else:
		reload_button.show()
		progress_bar.hide()
