extends GdUnitTestSuite

const PreviewScene = preload("res://addons/asset_placer/ui/components/asset_resource_preview.tscn")

var _preview: AssetResourcePreview
var _coordinator: ThumbnailGenerationCoordinator
var _saved_settings: AssetPlacerSettingsRepository
var _saved_cache: ThumbnailCacheStore
var _saved_coordinator: ThumbnailGenerationCoordinator


class MemoryCache:
	extends ThumbnailCacheStore

	var placeholder: Texture2D = GradientTexture2D.new()
	var placeholder_requests: int = 0
	var thumbnail: AssetThumbnail
	var texture_at_lookup: Texture2D
	var identifier_at_lookup: String

	# The base constructor calls this; never create the on-disk cache in tests.
	func ensure_cache_dir() -> bool:
		return true

	func identifier_for_asset(asset: AssetResource) -> String:
		texture_at_lookup = thumbnail.texture
		identifier_at_lookup = thumbnail._thumbnail_identifier
		return asset.id

	func get_placeholder_texture() -> Texture2D:
		placeholder_requests += 1
		return placeholder


func before_test() -> void:
	_saved_settings = AssetPlacerSettingsRepository.instance
	_saved_cache = ThumbnailCacheStore.instance
	_saved_coordinator = ThumbnailGenerationCoordinator.instance
	AssetPlacerSettingsRepository.instance = null
	ThumbnailCacheStore.instance = null
	_coordinator = ThumbnailGenerationCoordinator.new()
	ThumbnailGenerationCoordinator.instance = _coordinator


func after_test() -> void:
	if is_instance_valid(_preview):
		_preview.free()
	_preview = null
	_coordinator.free()
	AssetPlacerSettingsRepository.instance = _saved_settings
	ThumbnailCacheStore.instance = _saved_cache
	ThumbnailGenerationCoordinator.instance = _saved_coordinator
	_saved_settings = null
	_saved_cache = null
	_saved_coordinator = null


func test_defaults_and_scale_use_immutable_baseline_not_assigned_geometry() -> void:
	_preview = PreviewScene.instantiate()
	_preview.size = Vector2(730, 910)
	_preview.set_meta("id", "assigned-before-ready")
	add_child(_preview)
	assert_str(_preview.get_meta("id")).is_equal("assigned-before-ready")
	assert_vector(AssetResourcePreview.BASE_SIZE).is_equal(Vector2(150, 200))
	assert_vector(_preview.default_size).is_equal(AssetResourcePreview.BASE_SIZE)
	assert_vector(_preview.custom_minimum_size).is_equal(AssetResourcePreview.BASE_SIZE)
	var settings := AssetPlacerSettings.default()
	for ui_scale in [0.2, 1.0, 2.0, 0.2]:
		_preview.size = Vector2(900, 1200)
		_preview.default_size = Vector2(800, 1000)
		settings.ui_scale = ui_scale
		_preview.set_settings(settings)
		assert_vector(_preview.custom_minimum_size).is_equal(
			AssetResourcePreview.BASE_SIZE * ui_scale
		)


func test_rebind_without_recycling_replaces_asset_label_and_thumbnail() -> void:
	_mount()
	var cache := _install_cache()
	var asset_a := _asset("a")
	var asset_b := _asset("b")
	_preview.set_asset(asset_a)
	var old_texture: Texture2D = _preview.asset_thumbnail.texture
	cache.placeholder = GradientTexture2D.new()
	_preview.set_asset(asset_b)

	assert_object(_preview.resource).is_same(asset_b)
	assert_str(_preview.label.text).is_equal(asset_b.name)
	assert_object(_preview.asset_thumbnail._resource).is_same(asset_b)
	assert_str(_preview.asset_thumbnail._thumbnail_identifier).is_equal(asset_b.id)
	assert_object(_preview.asset_thumbnail.texture).is_same(cache.placeholder)
	assert_bool(_preview.asset_thumbnail.texture == old_texture).is_false()
	assert_object(cache.texture_at_lookup).is_null()
	assert_str(cache.identifier_at_lookup).is_empty()
	assert_bool(_preview.button.disabled).is_false()
	assert_bool(_preview.asset_thumbnail.is_processing()).is_true()


func test_clear_releases_asset_texture_selection_metadata_and_processing_without_signals() -> void:
	_mount()
	_install_cache()
	var asset := _asset("a")
	var asset_ref: WeakRef = weakref(asset)
	_preview.set_asset(asset)
	asset = null
	var texture: Texture2D = GradientTexture2D.new()
	var texture_ref: WeakRef = weakref(texture)
	_preview.asset_thumbnail.texture = texture
	texture = null
	_preview.asset_thumbnail.last_time_modified = 123
	_preview.set_meta("id", "old-id")
	_preview.select_not_signal(true)
	var toggles: Array[bool] = []
	_preview.button.toggled.connect(func(pressed: bool): toggles.append(pressed))

	_preview.clear_asset()
	_preview.clear_asset()

	_assert_cleared()
	assert_object(asset_ref.get_ref()).is_null()
	assert_object(texture_ref.get_ref()).is_null()
	assert_array(toggles).is_empty()


func test_null_assignment_clears_and_rebind_restores_the_view() -> void:
	_mount()
	_preview.set_asset(_asset("a"))
	_preview.select_not_signal(true)
	_preview.set_asset(null)
	_assert_cleared()
	var current := _asset("b")
	_preview.set_asset(current)
	assert_object(_preview.resource).is_same(current)
	assert_str(_preview.label.text).is_equal(current.name)
	assert_object(_preview.asset_thumbnail._resource).is_same(current)
	assert_bool(_preview.button.disabled).is_false()
	assert_bool(_preview.button.button_pressed).is_false()
	assert_bool(_preview.asset_thumbnail.is_processing()).is_true()


func test_cleared_view_ignores_clicks_and_thumbnail_notifications() -> void:
	_mount()
	var cache := _install_cache()
	var clicks: Array[AssetResource] = []
	_preview.left_clicked.connect(func(asset: AssetResource): clicks.append(asset))
	_preview.right_clicked.connect(func(asset: AssetResource): clicks.append(asset))
	var asset := _asset("a")
	_preview.set_asset(asset)
	_preview.clear_asset()
	var requests: int = cache.placeholder_requests

	_preview.button.toggled.emit(true)
	_preview._gui_input(_right_click())
	_coordinator.thumbnail_updated.emit(asset.id, "unused")
	_coordinator.thumbnail_updated.emit("", "unused")

	assert_array(clicks).is_empty()
	assert_int(cache.placeholder_requests).is_equal(requests)
	_assert_cleared()


func test_late_notification_for_old_binding_is_ignored_but_current_one_refreshes() -> void:
	_mount()
	var cache := _install_cache()
	var asset_a := _asset("a")
	var asset_b := _asset("b")
	_preview.set_asset(asset_a)
	_preview.set_asset(asset_b)
	var current_texture: Texture2D = _preview.asset_thumbnail.texture
	cache.placeholder = GradientTexture2D.new()
	var requests: int = cache.placeholder_requests

	_coordinator.thumbnail_updated.emit(asset_a.id, "unused")
	assert_int(cache.placeholder_requests).is_equal(requests)
	assert_object(_preview.asset_thumbnail.texture).is_same(current_texture)
	_coordinator.thumbnail_updated.emit(asset_b.id, "unused")
	assert_int(cache.placeholder_requests).is_equal(requests + 1)
	assert_object(_preview.asset_thumbnail.texture).is_same(cache.placeholder)


func test_clicks_emit_once_with_current_asset_after_rebind_and_recycle() -> void:
	_mount()
	var left_clicks: Array[AssetResource] = []
	var right_clicks: Array[AssetResource] = []
	_preview.left_clicked.connect(func(asset: AssetResource): left_clicks.append(asset))
	_preview.right_clicked.connect(func(asset: AssetResource): right_clicks.append(asset))
	var asset_a := _asset("a")
	var asset_b := _asset("b")
	_preview.set_asset(asset_a)
	_preview.set_asset(asset_b)
	_preview.button.button_pressed = true
	_preview._gui_input(_right_click())
	assert_array(left_clicks).contains_exactly([asset_b])
	assert_array(right_clicks).contains_exactly([asset_b])

	_preview.clear_asset()
	_preview.set_asset(asset_a)
	_preview.select_not_signal(true)
	assert_int(left_clicks.size()).is_equal(1)
	_preview.button.button_pressed = false
	assert_array(left_clicks).contains_exactly([asset_b, asset_a])
	assert_int(_preview.button.toggled.get_connections().size()).is_equal(1)
	assert_int(_coordinator.thumbnail_updated.get_connections().size()).is_equal(1)


func test_thumbnail_without_services_clears_old_texture_and_handles_null_directly() -> void:
	ThumbnailGenerationCoordinator.instance = null
	_mount()
	var thumbnail: AssetThumbnail = _preview.asset_thumbnail
	assert_bool(thumbnail.is_processing()).is_false()
	_preview.set_asset(null)
	thumbnail.texture = GradientTexture2D.new()
	thumbnail.set_resource(_asset("a"))
	assert_object(thumbnail.texture).is_null()
	assert_bool(thumbnail.is_processing()).is_true()
	assert_str(thumbnail._thumbnail_identifier).is_empty()
	thumbnail.last_time_modified = 123
	thumbnail.texture = GradientTexture2D.new()
	thumbnail.set_resource(null)
	_assert_cleared()


func _mount() -> void:
	_preview = PreviewScene.instantiate()
	add_child(_preview)


func _install_cache() -> MemoryCache:
	var cache := MemoryCache.new()
	cache.thumbnail = _preview.asset_thumbnail
	ThumbnailCacheStore.instance = cache
	return cache


func _asset(suffix: String) -> AssetResource:
	return AssetResource.new("res://nonexistent_preview_test_%s.tscn" % suffix, "Asset %s" % suffix)


func _right_click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	return event


func _assert_cleared() -> void:
	assert_object(_preview.resource).is_null()
	assert_str(_preview.label.text).is_empty()
	assert_bool(_preview.button.button_pressed).is_false()
	assert_bool(_preview.button.disabled).is_true()
	assert_bool(_preview.has_meta("id")).is_false()
	assert_object(_preview.asset_thumbnail._resource).is_null()
	assert_str(_preview.asset_thumbnail._thumbnail_identifier).is_empty()
	assert_int(_preview.asset_thumbnail.last_time_modified).is_zero()
	assert_object(_preview.asset_thumbnail.texture).is_null()
	assert_bool(_preview.asset_thumbnail.is_processing()).is_false()
