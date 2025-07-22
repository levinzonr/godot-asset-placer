@tool
extends Control
class_name  AssetResourcePreview

signal left_clicked(asset: AssetResource)
signal right_clicked(asset: AssetResource)

@onready var label = %Label
@onready var asset_thumbnail = %AssetThumbnail
var resource: AssetResource

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_asset(asset: AssetResource):
	self.resource = asset
	label.text = asset.name
	asset_thumbnail.set_resource(asset)
	

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			left_clicked.emit(resource)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			right_clicked.emit(resource)
			
