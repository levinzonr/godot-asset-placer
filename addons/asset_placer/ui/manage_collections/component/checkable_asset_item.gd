@tool
extends Button

var asset: AssetResource


func _ready():
	text = asset.name
	if asset.has_resource():
		icon = AssetThumbnailTexture2D.new(asset.get_resource())
