@tool
class_name AssetPickerDialog
extends PopupPanel

signal asset_picked(asset: AssetResource)

var presenter := AssetLibraryPresenter.new()

var _preview_resource: PackedScene = preload(
	"res://addons/asset_placer/ui/components/asset_resource_preview.tscn"
)

@onready var _search_field: LineEdit = %SearchField
@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _assets_flow: HFlowContainer = %AssetsFlow
@onready var _empty_all_view: Control = %EmptyAllView
@onready var _empty_search_view: Control = %EmptySearchView


func _ready() -> void:
	if is_part_of_edited_scene():
		return

	_search_field.text_changed.connect(presenter.on_query_change)
	presenter.assets_loaded.connect(_show_assets)
	presenter.show_empty_view.connect(_show_empty_view)
	presenter.on_ready()


func _show_assets(assets: Array[AssetResource]) -> void:
	_assets_flow.show()
	_empty_all_view.hide()
	_empty_search_view.hide()
	_scroll_container.show()
	for child in _assets_flow.get_children():
		child.queue_free()
	for asset in assets:
		var preview := _preview_resource.instantiate() as AssetResourcePreview
		preview.left_clicked.connect(_on_preview_clicked)
		_assets_flow.add_child(preview)
		preview.set_asset(asset)


func _on_preview_clicked(asset: AssetResource) -> void:
	if not is_instance_valid(asset.get_resource()):
		push_error("Invalid asset")
		return
	asset_picked.emit(asset)
	queue_free()


func _show_empty_view(type: AssetLibraryPresenter.EmptyType) -> void:
	match type:
		AssetLibraryPresenter.EmptyType.None:
			_assets_flow.show()
			_empty_all_view.hide()
			_empty_search_view.hide()
			_scroll_container.show()
		AssetLibraryPresenter.EmptyType.Search:
			_clear_assets()
			_assets_flow.hide()
			_empty_all_view.hide()
			_empty_search_view.show()
			_scroll_container.show()
		AssetLibraryPresenter.EmptyType.All, AssetLibraryPresenter.EmptyType.Collection:
			_clear_assets()
			_assets_flow.hide()
			_empty_search_view.hide()
			_empty_all_view.show()
			_scroll_container.show()


func _clear_assets() -> void:
	for child in _assets_flow.get_children():
		child.queue_free()


static func open(on_pick: Callable) -> AssetPickerDialog:
	var dialog := (
		(
			load("res://addons/asset_placer/ui/asset_picker_dialog/asset_picker_dialog.tscn")
			. instantiate()
		)
		as AssetPickerDialog
	)
	dialog.asset_picked.connect(on_pick, CONNECT_ONE_SHOT)
	EditorInterface.popup_dialog_centered(dialog)
	return dialog
