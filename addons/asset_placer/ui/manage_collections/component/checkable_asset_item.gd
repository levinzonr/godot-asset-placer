@tool
extends Button

var asset: AssetResource

	
func _ready():
	text = asset.name
	icon = AssetThumbnailTexture2D.new(asset.scene)
	
	
