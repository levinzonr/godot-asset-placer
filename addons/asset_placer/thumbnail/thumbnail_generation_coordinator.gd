@tool
class_name ThumbnailGenerationCoordinator
extends Node

signal started(total: int)
signal progress(done: int, total: int, current_path: String)
signal failed_item(path: String, error: String)
signal thumbnail_updated(identifier: String, thumbnail_path: String)
signal finished(success: int, failed: int, skipped: int)
signal canceled(success: int, failed: int, skipped: int)

const FRAME_YIELD_INTERVAL := 4

static var instance: ThumbnailGenerationCoordinator

var _running := false
var _cancel_requested := false
var _cache: ThumbnailCacheStore
var _renderer: ThumbnailRenderService


func _ready():
	instance = self
	_cache = ThumbnailCacheStore.instance
	_renderer = ThumbnailRenderService.instance


func _exit_tree():
	if instance == self:
		instance = null


func is_running() -> bool:
	return _running


func request_cancel():
	_cancel_requested = true


func start_regeneration(
	assets: Array[AssetResource] = [], stale_only: bool = true
) -> bool:
	if _running:
		return false
	if not _ensure_services():
		return false

	var source_assets := assets
	if source_assets.is_empty():
		var library := AssetLibraryManager.get_asset_library()
		if library == null:
			return false
		source_assets = library.get_assets().duplicate()

	_running = true
	_cancel_requested = false
	call_deferred("_run_regeneration", source_assets, stale_only)
	return true


func generate_for_asset(asset: AssetResource, stale_only: bool = true) -> bool:
	if not is_instance_valid(asset):
		return false
	return start_regeneration([asset], stale_only)


func generate_for_resource_path(resource_path: String, stale_only: bool = true) -> bool:
	if resource_path.is_empty():
		return false
	var library := AssetLibraryManager.get_asset_library()
	if library == null:
		return false
	for asset in library.get_assets():
		if asset.get_path() == resource_path:
			return start_regeneration([asset], stale_only)
	return false


func _ensure_services() -> bool:
	if _cache == null:
		_cache = ThumbnailCacheStore.instance
	if _renderer == null:
		_renderer = ThumbnailRenderService.instance
	return _cache != null and _renderer != null


func _run_regeneration(assets: Array[AssetResource], stale_only: bool):
	var to_process := _filter_assets(assets)
	var total := to_process.size()
	var success := 0
	var failed := 0
	var skipped := 0
	var done := 0

	started.emit(total)

	for asset in to_process:
		var asset_path := asset.get_path()
		if _cancel_requested:
			break

		if stale_only and not _cache.is_missing_or_stale(asset):
			skipped += 1
		else:
			var result: Dictionary = await _renderer.render_asset(asset)
			if result.get("ok", false):
				var identifier := _cache.identifier_for_asset(asset)
				var image: Image = result.get("image")
				if _cache.save_thumbnail(identifier, image):
					success += 1
					thumbnail_updated.emit(
						identifier, _cache.thumbnail_path_for_identifier(identifier)
					)
				else:
					failed += 1
					failed_item.emit(asset_path, "Could not save rendered thumbnail")
			else:
				failed += 1
				failed_item.emit(asset_path, str(result.get("error", "Unknown error")))

		done += 1
		progress.emit(done, total, asset_path)
		if done % FRAME_YIELD_INTERVAL == 0:
			await get_tree().process_frame

	_running = false

	if _cancel_requested:
		canceled.emit(success, failed, skipped)
	else:
		finished.emit(success, failed, skipped)


func _filter_assets(assets: Array[AssetResource]) -> Array[AssetResource]:
	var filtered: Array[AssetResource] = []
	for asset in assets:
		if is_instance_valid(asset) and asset.has_resource() and not asset.get_path().is_empty():
			filtered.append(asset)
	return filtered
