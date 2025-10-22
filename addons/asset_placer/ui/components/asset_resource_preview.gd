@tool
extends Button
class_name  AssetResourcePreview

signal left_clicked(asset: AssetResource)
signal right_clicked(asset: AssetResource)

@onready var label = %Label
@onready var asset_thumbnail = %AssetThumbnail
var resource: AssetResource
var settings_repo = AssetPlacerSettingsRepository.instance
var default_size: Vector2

func _ready():
	default_size = size
	mouse_filter = Control.MOUSE_FILTER_STOP
	toggled.connect(func(_a): left_clicked.emit(resource))
	set_settings(settings_repo.get_settings())
	settings_repo.settings_changed.connect(set_settings)

func set_asset(asset: AssetResource):
	self.resource = asset
	label.text = asset.name
	asset_thumbnail.set_resource(asset)

func set_settings(settings: AssetPlacerSettings):
	custom_minimum_size = default_size * settings.ui_scale

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			right_clicked.emit(resource)
			
