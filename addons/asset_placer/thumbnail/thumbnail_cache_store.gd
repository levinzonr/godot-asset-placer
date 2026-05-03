@tool
class_name ThumbnailCacheStore
extends RefCounted

const CACHE_DIR := "user://asset_placer/thumbnails"
const PLACEHOLDER_TEXTURE_PATH := "res://addons/asset_placer/icon.png"

static var instance: ThumbnailCacheStore

var _placeholder_texture: Texture2D


func _init():
	instance = self
	ensure_cache_dir()


func ensure_cache_dir() -> bool:
	var cache_dir_global := ProjectSettings.globalize_path(CACHE_DIR)
	if DirAccess.dir_exists_absolute(cache_dir_global):
		return true
	return DirAccess.make_dir_recursive_absolute(cache_dir_global) == OK


func identifier_for_asset(asset: AssetResource) -> String:
	if not is_instance_valid(asset):
		return ""
	return _normalize_identifier(asset.id)


func identifier_for_resource_path(resource_path: String) -> String:
	if resource_path.is_empty():
		return ""
	var uid: String = ResourceIdCompat.path_to_uid(resource_path)
	var identifier: String = uid if not uid.is_empty() else resource_path
	return _normalize_identifier(identifier)


func thumbnail_path_for_identifier(identifier: String) -> String:
	if identifier.is_empty():
		return ""
	return "%s/%s.png" % [CACHE_DIR, identifier.md5_text()]


func thumbnail_exists(identifier: String) -> bool:
	var thumbnail_path := thumbnail_path_for_identifier(identifier)
	return not thumbnail_path.is_empty() and FileAccess.file_exists(thumbnail_path)


func is_missing_or_stale(asset: AssetResource) -> bool:
	if not is_instance_valid(asset) or not asset.has_resource():
		return false
	var identifier := identifier_for_asset(asset)
	return is_missing_or_stale_path(identifier, asset.get_path())


func is_missing_or_stale_path(identifier: String, source_path: String) -> bool:
	if identifier.is_empty() or source_path.is_empty():
		return true
	var thumbnail_path := thumbnail_path_for_identifier(identifier)
	if not FileAccess.file_exists(thumbnail_path):
		return true
	var source_mtime := FileAccess.get_modified_time(source_path)
	if source_mtime <= 0:
		return true
	var thumbnail_mtime := FileAccess.get_modified_time(thumbnail_path)
	return thumbnail_mtime < source_mtime


func load_texture(identifier: String) -> Texture2D:
	if identifier.is_empty():
		return null
	var thumbnail_path := thumbnail_path_for_identifier(identifier)
	if not FileAccess.file_exists(thumbnail_path):
		return null
	var image := Image.load_from_file(thumbnail_path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func save_thumbnail(identifier: String, image: Image) -> bool:
	if identifier.is_empty() or image == null or image.is_empty():
		return false
	if not ensure_cache_dir():
		return false
	var thumbnail_path := thumbnail_path_for_identifier(identifier)
	return image.save_png(thumbnail_path) == OK


func get_placeholder_texture() -> Texture2D:
	if not is_instance_valid(_placeholder_texture):
		_placeholder_texture = load(PLACEHOLDER_TEXTURE_PATH)
	return _placeholder_texture


func _normalize_identifier(identifier: String) -> String:
	return identifier.strip_edges()
