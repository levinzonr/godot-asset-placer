@tool
class_name AssetThumbnail
extends TextureRect

var last_time_modified = 0

var _resource: AssetResource
var _thumbnail_identifier := ""


func _process(_delta):
	if not is_part_of_edited_scene() and is_instance_valid(_resource) and _resource.has_resource():
		var new_time_modified = FileAccess.get_modified_time(_resource.get_path())
		if new_time_modified != last_time_modified:
			_refresh_thumbnail(true)


func set_resource(resource: AssetResource):
	_resource = resource
	var cache_store := ThumbnailCacheStore.instance
	_thumbnail_identifier = cache_store.identifier_for_asset(resource) if cache_store else ""
	_refresh_thumbnail(true)


func _ready():
	var coordinator := ThumbnailGenerationCoordinator.instance
	if is_instance_valid(coordinator):
		coordinator.thumbnail_updated.connect(_on_thumbnail_updated)


func _refresh_thumbnail(request_regeneration: bool):
	var cache_store := ThumbnailCacheStore.instance
	if cache_store == null:
		return
	if (
		is_part_of_edited_scene()
		or not is_instance_valid(_resource)
		or not _resource.has_resource()
	):
		texture = cache_store.get_placeholder_texture()
		return

	last_time_modified = FileAccess.get_modified_time(_resource.get_path())
	var cached_texture := cache_store.load_texture(_thumbnail_identifier)
	var is_stale := cache_store.is_missing_or_stale(_resource)

	if is_instance_valid(cached_texture):
		texture = cached_texture
	else:
		texture = cache_store.get_placeholder_texture()

	if request_regeneration and is_stale:
		var coordinator := ThumbnailGenerationCoordinator.instance
		if is_instance_valid(coordinator) and not coordinator.is_running():
			coordinator.generate_for_asset(_resource, true)


func _on_thumbnail_updated(identifier: String, _thumbnail_path: String):
	if identifier == _thumbnail_identifier:
		_refresh_thumbnail(false)
