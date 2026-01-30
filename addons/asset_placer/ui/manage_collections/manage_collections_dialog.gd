@tool
class_name ManageCollectionsDialog
extends PopupPanel

var collection_item_res = preload(
	"res://addons/asset_placer/ui/manage_collections/component/checkable_collection_item.tscn"
)
var asset_item_res = preload(
	"res://addons/asset_placer/ui/manage_collections/component/checkable_asset_item.tscn"
)
var _active_collection: AssetCollection = null
var _batch_mode: bool = false
var _button_group: ButtonGroup
var _ctrl_held: bool = false
var _last_selected_index: int = -1

@onready var assets_container: Container = %AssetsContainer
@onready var presenter: ManageCollectionsPresenter = ManageCollectionsPresenter.new()
@onready var inactive_collections_container: Container = %InactiveCollectionsContainer
@onready var active_collections_container: Container = %ActiveCollectionsContainer
@onready var filter_assets_line_edit: LineEdit = %FilterAssetsLineEdit
@onready var no_active_collections_empty_view = %NoActiveCollectionsEmptyView
@onready var no_in_active_collections_empty_view = %NoInActiveCollectionsEmptyView
@onready var empty_assets_empty_view = %EmptyAssetsEmptyView
@onready var batch_select_check_box: CheckBox = %BatchSelectCheckBox


func _ready():
	presenter.show_inactive_collections.connect(show_inactive_collections)
	presenter.show_active_collections.connect(show_active_collections)
	presenter.show_partial_collections.connect(show_partial_collections)
	filter_assets_line_edit.text_changed.connect(func(text): presenter.filter_assets(text))
	presenter.show_assets.connect(show_assets)
	batch_select_check_box.toggled.connect(_on_batch_mode_toggled)
	presenter.ready()


func _input(event: InputEvent):
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.keycode == KEY_CTRL or key_event.keycode == KEY_META:
			_ctrl_held = key_event.pressed
			if _ctrl_held and not _batch_mode:
				_set_batch_mode(true)
				batch_select_check_box.set_pressed_no_signal(true)

		# CMD/CTRL + A to select all
		if key_event.pressed and key_event.keycode == KEY_A:
			if key_event.ctrl_pressed or key_event.meta_pressed:
				_select_all_assets()


func _on_batch_mode_toggled(pressed: bool):
	_set_batch_mode(pressed)


func _set_batch_mode(enabled: bool):
	if _batch_mode == enabled:
		return
	_batch_mode = enabled

	if enabled:
		# Remove buttons from group to allow multi-select
		for button in assets_container.get_children():
			if button is Button:
				button.button_group = null
	else:
		# Re-add buttons to group, keep first selected one
		var first_selected: Button = null
		for button in assets_container.get_children():
			if button is Button:
				if button.button_pressed and first_selected == null:
					first_selected = button
				button.button_group = _button_group
				button.set_pressed_no_signal(false)

		if first_selected:
			first_selected.set_pressed_no_signal(true)
			presenter.select_assets([first_selected.asset])
		elif assets_container.get_child_count() > 0:
			var first_button = assets_container.get_child(0) as Button
			if first_button:
				first_button.set_pressed_no_signal(true)
				presenter.select_assets([first_button.asset])


func show_assets(assets: Array[AssetResource]):
	show_empty_assets_view(assets.is_empty())
	for child: Control in assets_container.get_children():
		child.queue_free()

	_button_group = ButtonGroup.new()
	_last_selected_index = -1

	for item in assets:
		var control := asset_item_res.instantiate() as Button
		if not _batch_mode:
			control.button_group = _button_group
		control.asset = item
		control.toggled.connect(_on_asset_toggled.bind(control))
		assets_container.add_child(control)

	if presenter.selected_assets.is_empty() and not assets.is_empty():
		var first_button = assets_container.get_child(0) as Button
		first_button.set_pressed_no_signal(true)
		_last_selected_index = 0
		presenter.select_assets([first_button.asset])


func _on_asset_toggled(pressed: bool, button: Button):
	var button_index = button.get_index()

	# Shift+click for range selection
	if pressed and Input.is_key_pressed(KEY_SHIFT) and _last_selected_index >= 0:
		_select_range(_last_selected_index, button_index)
		return

	if _batch_mode:
		if pressed:
			_last_selected_index = button_index
		_update_batch_selection()
	else:
		if pressed:
			_last_selected_index = button_index
			presenter.select_assets([button.asset])


func _update_batch_selection():
	var selected: Array[AssetResource] = []
	for child in assets_container.get_children():
		if child is Button and child.button_pressed:
			selected.append(child.asset)
	presenter.select_assets(selected)


func _select_all_assets():
	# Enable batch mode if not already
	if not _batch_mode:
		_set_batch_mode(true)
		batch_select_check_box.set_pressed_no_signal(true)

	# Select all asset buttons
	for child in assets_container.get_children():
		if child is Button:
			child.set_pressed_no_signal(true)

	_update_batch_selection()


func _select_range(from_index: int, to_index: int):
	# Enable batch mode if not already
	if not _batch_mode:
		_set_batch_mode(true)
		batch_select_check_box.set_pressed_no_signal(true)

	# Determine range bounds
	var start_idx = mini(from_index, to_index)
	var end_idx = maxi(from_index, to_index)

	# Select all buttons in range
	for i in range(assets_container.get_child_count()):
		var child = assets_container.get_child(i)
		if child is Button:
			if i >= start_idx and i <= end_idx:
				child.set_pressed_no_signal(true)

	_last_selected_index = to_index
	_update_batch_selection()


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
		control.button.icon = EditorIconTexture2D.new("Add")
		control.button.text = "Add"
		control.move_up_button.hide()
		control.move_down_button.hide()
		control.button.pressed.connect(func(): presenter.add_to_collection(item))


func show_active_collections(collections: Array[AssetCollection]):
	for child: Control in active_collections_container.get_children():
		child.queue_free()

	for item in collections:
		var control := collection_item_res.instantiate() as Control
		active_collections_container.add_child(control)
		control.set_collection(item)
		control.button.text = "Remove"
		control.button.icon = EditorIconTexture2D.new("Clear")
		control.button.pressed.connect(func(): presenter.remove_from_collection(item))

		# Set Primary button (replaces move up/down)
		control.move_up_button.icon = EditorIconTexture2D.new("Favorites")
		control.move_up_button.tooltip_text = "Set as Primary"
		control.move_up_button.disabled = collections.find(item) == 0
		control.move_up_button.pressed.connect(func(): presenter.set_primary_collection(item))
		control.move_down_button.hide()


func show_partial_collections(collections: Array[AssetCollection]):
	# Partial collections are shown after full collections with an indicator
	for item in collections:
		var control := collection_item_res.instantiate() as Control
		active_collections_container.add_child(control)
		control.set_collection(item, true)  # Pass partial indicator flag
		control.button.text = "Remove"
		control.button.icon = EditorIconTexture2D.new("Clear")
		control.button.pressed.connect(func(): presenter.remove_from_collection(item))

		# Hide primary button for partial (can't set primary when not all have it)
		control.move_up_button.hide()
		control.move_down_button.hide()

	# Update empty view based on total collections
	var has_collections = active_collections_container.get_child_count() > 0
	show_empty_active_collections(not has_collections)


func show_empty_assets_view(visible: bool):
	empty_assets_empty_view.visible = visible
	assets_container.visible = !visible


func show_empty_active_collections(visible: bool):
	active_collections_container.visible = !visible
	no_active_collections_empty_view.visible = visible


func show_empty_inactive_collections(visible: bool):
	inactive_collections_container.visible = !visible
	no_in_active_collections_empty_view.visible = visible
