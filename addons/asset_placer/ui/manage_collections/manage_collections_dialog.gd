@tool
class_name ManageCollectionsDialog
extends PopupPanel

var initial_asset_id: String = ""
var _settings_repository: AssetPlacerSettingsRepository

var _collection_item_res = preload(
	"res://addons/asset_placer/ui/manage_collections/component/checkable_collection_item.tscn"
)
var _asset_item_res = preload(
	"res://addons/asset_placer/ui/manage_collections/component/checkable_asset_item.tscn"
)

@onready var _presenter: ManageCollectionsPresenter = ManageCollectionsPresenter.new()
@onready var _assets_container: Container = %AssetsContainer
@onready var _assets_scroll: ScrollContainer = %ScrollContainer
@onready var _active_collections_container: Container = %ActiveCollectionsContainer
@onready var _inactive_collections_container: Container = %InactiveCollectionsContainer
@onready var _filter_line_edit: LineEdit = %FilterAssetsLineEdit
@onready var _empty_assets_view = %EmptyAssetsEmptyView
@onready var _empty_active_view = %NoActiveCollectionsEmptyView
@onready var _empty_available_view = %NoInActiveCollectionsEmptyView
@onready var _tip_label = %Label


func _ready():
	_settings_repository = AssetPlacerSettingsRepository.instance
	_presenter.assets_changed.connect(_on_assets_changed)
	_presenter.selection_changed.connect(_on_selection_changed)
	_presenter.collections_changed.connect(_on_collections_changed)
	_filter_line_edit.text_changed.connect(_presenter.filter_assets)
	_presenter.ready(initial_asset_id)
	size_changed.connect(_on_size_changed)
	call_deferred("_restore_size")

	var range_select_binding = APInputOption.mouse_press(
		MouseButton.MOUSE_BUTTON_LEFT, KeyModifierMask.KEY_MASK_SHIFT
	)

	var multi_select_modifier = (
		KeyModifierMask.KEY_MASK_META if OS.get_name() == "macOS" else KeyModifierMask.KEY_MASK_CTRL
	)
	var multi_select_binding = APInputOption.mouse_press(
		MouseButton.MOUSE_BUTTON_LEFT, multi_select_modifier
	)

	_tip_label.text = range_select_binding.get_display_name() + " for Range selection"
	_tip_label.text += " and "
	_tip_label.text += multi_select_binding.get_display_name() + " for Multi selection"


func _input(event: InputEvent):
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_A:
			if key_event.ctrl_pressed or key_event.meta_pressed:
				_presenter.select_all()


func _on_assets_changed(assets: Array[AssetResource]):
	var show_empty := assets.is_empty()
	_empty_assets_view.visible = show_empty
	_assets_container.visible = not show_empty

	for child in _assets_container.get_children():
		child.queue_free()

	for i in assets.size():
		var asset := assets[i]
		var button := _asset_item_res.instantiate() as Button
		button.asset = asset
		button.toggled.connect(_on_asset_pressed.bind(i))
		_assets_container.add_child(button)


func _on_selection_changed(indices: PackedInt32Array, _batch_mode: bool):
	var buttons := _assets_container.get_children()
	for i in buttons.size():
		var button := buttons[i] as Button
		if button:
			var selected := indices.find(i) != -1
			button.set_pressed_no_signal(selected)
			if selected and indices.size() == 1:
				await get_tree().process_frame
				if is_instance_valid(button) and button.is_inside_tree():
					_assets_scroll.ensure_control_visible(button)


func _on_collections_changed(
	collections: Array[ManageCollectionsPresenter.CollectionState], batch_mode: bool
):
	for child in _active_collections_container.get_children():
		child.queue_free()
	for child in _inactive_collections_container.get_children():
		child.queue_free()

	var has_active := false
	var has_available := false

	for cs in collections:
		if cs.is_full() or cs.is_partial():
			has_active = true
			var item := _collection_item_res.instantiate()
			_active_collections_container.add_child(item)
			var batch_count := cs.assigned_count if batch_mode else 1
			item.configure_as_assigned(cs.collection, cs.is_partial(), cs.is_primary, batch_count)
			item.action_pressed.connect(_presenter.remove_from_collection.bind(cs.collection))
			item.set_primary_pressed.connect(_presenter.set_primary_collection.bind(cs.collection))

		if cs.is_available():
			has_available = true
			var item := _collection_item_res.instantiate()
			_inactive_collections_container.add_child(item)
			var batch_count := (cs.total_selected - cs.assigned_count) if batch_mode else 1
			item.configure_as_available(cs.collection, batch_count)
			item.action_pressed.connect(_presenter.add_to_collection.bind(cs.collection))

	_active_collections_container.visible = has_active
	_empty_active_view.visible = not has_active
	_inactive_collections_container.visible = has_available
	_empty_available_view.visible = not has_available


func _on_asset_pressed(_pressed: bool, index: int):
	var mode := _get_select_mode()
	_presenter.toggle_asset(index, mode)


func _get_select_mode() -> ManageCollectionsPresenter.SelectMode:
	if Input.is_key_pressed(KEY_SHIFT):
		return ManageCollectionsPresenter.SelectMode.RANGE
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
		return ManageCollectionsPresenter.SelectMode.MULTI
	return ManageCollectionsPresenter.SelectMode.SINGLE


func _restore_size():
	size = _settings_repository.get_manage_collections_dialog_size()


func _on_size_changed():
	_settings_repository.set_manage_collections_dialog_size(size)


static func open(asset_id: String = ""):
	var dialog: ManageCollectionsDialog = (
		load("res://addons/asset_placer/ui/manage_collections/manage_collections_dialog.tscn")
		. instantiate()
	)
	dialog.initial_asset_id = asset_id
	EditorInterface.popup_dialog_centered(dialog)
