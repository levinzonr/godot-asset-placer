@tool
extends PopupPanel
class_name ManageCollectionsDialog
@onready var assets_container: Container = %AssetsContainer

@onready var presenter: ManageCollectionsPresenter = ManageCollectionsPresenter.new()
@onready var inactive_collections_container: Container = %InactiveCollectionsContainer
@onready var active_collections_container: Container = %ActiveCollectionsContainer
var collection_item_res = preload("res://addons/asset_placer/ui/manage_collections/component/checkable_collection_item.tscn")
var asset_item_res=  preload("res://addons/asset_placer/ui/manage_collections/component/checkable_asset_item.tscn")
@onready var filter_assets_line_edit: LineEdit = %FilterAssetsLineEdit

@onready var no_active_collections_empty_view = %NoActiveCollectionsEmptyView
@onready var no_in_active_collections_empty_view = %NoInActiveCollectionsEmptyView
@onready var empty_assets_empty_view = %EmptyAssetsEmptyView

var _active_collection : AssetCollection = null

func _ready():
	presenter.show_inactive_collections.connect(show_inactive_collections)
	presenter.show_active_collections.connect(show_active_collections)
	filter_assets_line_edit.text_changed.connect(func(text):
		presenter.filter_assets(text)
	)
	presenter.show_assets.connect(show_assets)
	presenter.ready()

func show_assets(assets: Array[AssetResource]):
	show_empty_assets_view(assets.is_empty())
	for child: Control in assets_container.get_children():
		child.queue_free()
		
	var button_group = ButtonGroup.new()	
	for item in assets:
		var control := asset_item_res.instantiate() as Button
		control.button_group = button_group
		control.asset = item
		assets_container.add_child(control)
	
	if presenter.active_asset == null && not assets.is_empty():
		var first_button = button_group.get_buttons()[0]
		first_button.set_pressed_no_signal(true)
		presenter.select_asset(first_button.asset)
		
	button_group.pressed.connect(func (t):
		presenter.select_asset(t.asset)
	)	
		
func select_collection(collection: AssetCollection):
	_active_collection = collection
	
func show_inactive_collections(collections: Array[AssetCollection]):
	show_empty_inactive_collections(collections.is_empty())
	for child: Control in inactive_collections_container.get_children():
		child.queue_free()
		
	for item in collections:
		var control := collection_item_res.instantiate() as Control
		inactive_collections_container.add_child(control)
		control.set_collection(item)
		control.button.icon = EditorIconTexture2D.new("ArrowUp")
		control.button.text = "Add"
		control.button.pressed.connect(func():
			presenter.add_to_collection(item)
		)
			
			
func show_active_collections(collections: Array[AssetCollection]):
	show_empty_active_collections(collections.is_empty())
	for child: Control in active_collections_container.get_children():
		child.queue_free()
		
	for item in collections:
		var control := collection_item_res.instantiate() as Control
		active_collections_container.add_child(control)
		control.set_collection(item)
		control.button.text = "Remove"
		control.button.icon = EditorIconTexture2D.new("ArrowDown")
		control.button.pressed.connect(func():
			presenter.remove_from_collection(item)
		)

func show_empty_assets_view(visible: bool):
	empty_assets_empty_view.visible = visible
	assets_container.visible = !visible			
			
func show_empty_active_collections(visible: bool):
	active_collections_container.visible = !visible
	no_active_collections_empty_view.visible = visible
	
func show_empty_inactive_collections(visible: bool):
	inactive_collections_container.visible = !visible
	no_in_active_collections_empty_view.visible = visible		
