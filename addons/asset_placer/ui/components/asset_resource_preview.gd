@tool
class_name AssetResourcePreview
extends Container

signal left_clicked(asset: AssetResource)
signal right_clicked(asset: AssetResource)

const BASE_SIZE: Vector2 = Vector2(150, 200)

var resource: AssetResource
var settings_repo = AssetPlacerSettingsRepository.instance
var default_size: Vector2 = BASE_SIZE

@onready var button = %Button
@onready var label = %Label
@onready var asset_thumbnail = %AssetThumbnail


func _ready():
	default_size = BASE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not button.toggled.is_connected(_on_button_toggled):
		button.toggled.connect(_on_button_toggled)
	if is_instance_valid(settings_repo):
		set_settings(settings_repo.get_settings())
		if not settings_repo.settings_changed.is_connected(set_settings):
			settings_repo.settings_changed.connect(set_settings)
	else:
		set_settings(AssetPlacerSettings.default())
	button.disabled = not is_instance_valid(resource)


func set_asset(asset: AssetResource):
	if not is_instance_valid(asset):
		clear_asset()
		return
	self.resource = asset
	button.disabled = false
	label.text = asset.name
	asset_thumbnail.set_resource(asset)


func clear_asset():
	resource = null
	label.text = ""
	button.set_pressed_no_signal(false)
	button.disabled = true
	if has_meta("id"):
		remove_meta("id")
	asset_thumbnail.clear_resource()


func set_settings(settings: AssetPlacerSettings):
	custom_minimum_size = BASE_SIZE * settings.ui_scale


func select_not_signal(selected: bool):
	button.set_pressed_no_signal(selected)


func _on_button_toggled(_pressed: bool):
	if is_instance_valid(resource):
		left_clicked.emit(resource)


func _gui_input(event):
	if not is_instance_valid(resource):
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			right_clicked.emit(resource)
