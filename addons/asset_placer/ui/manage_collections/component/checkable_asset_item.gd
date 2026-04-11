@tool
extends Button

var asset: AssetResource
@onready var cirlce_icon = preload(
	"res://addons/asset_placer/ui/asset_collections_window/components/collection_circle.svg"
)
@onready var collections_container: Container = %CollectionsContainer


func _ready():
	text = asset.name
	if asset.has_resource():
		icon = AssetThumbnailTexture2D.new(asset.get_resource())
	_show_collections()


func _show_collections():
	for collection_id in asset.tags:
		var collection = AssetLibraryManager.get_asset_library().get_collection(collection_id)
		var collection_icon = TextureRect.new()
		collection_icon.texture = cirlce_icon
		collection_icon.modulate = collection.background_color
		collection_icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		collection_icon.custom_minimum_size = Vector2(25, 25)
		collection_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		collections_container.add_child(collection_icon)
