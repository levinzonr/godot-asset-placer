extends GdUnitTestSuite

const LibraryRecycler = preload(
	"res://addons/asset_placer/ui/asset_library_window/asset_library_recycler_view.gd"
)
const Preview = preload("res://addons/asset_placer/ui/components/asset_resource_preview.gd")

var _view: LibraryRecycler
var _repository: MemorySettings
var _cache: MemoryCache
var _saved_settings: AssetPlacerSettingsRepository
var _saved_cache: ThumbnailCacheStore
var _saved_coordinator: ThumbnailGenerationCoordinator


class MemorySettings:
	extends AssetPlacerSettingsRepository

	var value: AssetPlacerSettings = AssetPlacerSettings.default()

	func _init() -> void:
		instance = self

	func get_settings() -> AssetPlacerSettings:
		return value


class MemoryCache:
	extends ThumbnailCacheStore

	var placeholder: GradientTexture2D = GradientTexture2D.new()
	var placeholder_reads: int = 0

	func _init() -> void:
		instance = self
		placeholder.width = 256
		placeholder.height = 256

	func get_placeholder_texture() -> Texture2D:
		placeholder_reads += 1
		return placeholder


func before_test() -> void:
	_saved_settings = AssetPlacerSettingsRepository.instance
	_saved_cache = ThumbnailCacheStore.instance
	_saved_coordinator = ThumbnailGenerationCoordinator.instance
	_repository = MemorySettings.new()
	_cache = MemoryCache.new()
	ThumbnailGenerationCoordinator.instance = null
	_view = LibraryRecycler.new()
	_view.size = Vector2(720, 480)
	var assets: Array[AssetResource] = []
	for index in range(200):
		assets.append(
			AssetResource.new("res://missing_settings_asset_%d.tscn" % index, "Asset %d" % index)
		)
	_view.set_assets(assets)


func after_test() -> void:
	if is_instance_valid(_view):
		_view.free()
	_view = null
	await _settle()
	assert_int(_repository.settings_changed.get_connections().size()).is_zero()
	AssetPlacerSettingsRepository.instance = _saved_settings
	ThumbnailCacheStore.instance = _saved_cache
	ThumbnailGenerationCoordinator.instance = _saved_coordinator
	_repository = null
	_cache = null
	_saved_settings = null
	_saved_cache = null
	_saved_coordinator = null


func test_initial_repository_scale_and_texture_minima_are_respected() -> void:
	_repository.value.ui_scale = 1.7
	add_child(_view)
	await _settle()
	_assert_scaled_geometry(1.7)


func test_settings_signal_changes_scale_in_both_directions_with_real_placeholder_texture() -> void:
	add_child(_view)
	await _settle()
	for ui_scale: float in [2.0, 0.2, 1.0, 0.2]:
		_repository.value = AssetPlacerSettings.default()
		_repository.value.ui_scale = ui_scale
		_repository.settings_changed.emit(_repository.value)
		await _settle()
		_assert_scaled_geometry(ui_scale)
		var width: float = _view.layout_manager.item_width
		var height: float = _view.layout_manager.item_height
		await _settle()
		assert_float(_view.layout_manager.item_width).is_equal(width)
		assert_float(_view.layout_manager.item_height).is_equal(height)
		assert_bool(_view.is_processing()).is_false()


func test_unrelated_settings_do_not_reload_thumbnails_or_change_library_geometry() -> void:
	add_child(_view)
	await _settle()
	var width: float = _view.layout_manager.item_width
	var height: float = _view.layout_manager.item_height
	var reads := _cache.placeholder_reads
	_repository.value.palette_item_scale = 2.0
	_repository.value.transform_step = 0.25
	_repository.value.rotation_step = 45.0
	_repository.value.show_toolbar_button = false
	_repository.value.update_channel = AssetPlacerSettings.UpdateChannel.Beta
	_repository.settings_changed.emit(_repository.value)
	await _settle()
	assert_int(_cache.placeholder_reads).is_equal(reads)
	assert_float(_view.layout_manager.item_width).is_equal(width)
	assert_float(_view.layout_manager.item_height).is_equal(height)
	_assert_scaled_geometry(1.0)


func test_theme_minima_with_texture_present_update_slots_without_overlap() -> void:
	_repository.value.ui_scale = 0.2
	var theme := Theme.new()
	_view.theme = theme
	add_child(_view)
	await _settle()
	var original_height: float = _view.layout_manager.item_height
	var normal := StyleBoxFlat.new()
	normal.content_margin_left = 80
	normal.content_margin_right = 80
	normal.content_margin_top = 120
	normal.content_margin_bottom = 120
	theme.set_stylebox("normal", "FlatButton", normal)
	await _settle()
	assert_float(_view.layout_manager.item_height).is_greater(original_height)
	_assert_scaled_geometry(0.2)


func test_disposal_releases_adapter_holders_and_all_repository_connections() -> void:
	add_child(_view)
	await _settle()
	var adapter_ref: WeakRef = weakref(_view.adapter)
	var holder_ref: WeakRef = weakref(_view.find_view_holder_for_adapter_position(0))
	assert_int(_repository.settings_changed.get_connections().size()).is_greater(1)
	_view.free()
	_view = null
	await _settle()
	assert_object(adapter_ref.get_ref()).is_null()
	assert_object(holder_ref.get_ref()).is_null()
	assert_array(_repository.settings_changed.get_connections()).is_empty()


func _settle() -> void:
	for frame in range(20):
		await get_tree().process_frame


func _assert_scaled_geometry(ui_scale: float) -> void:
	var positions := _view.get_visible_range()
	assert_int(positions.y - positions.x).is_greater(0)
	for item_position in range(positions.x, positions.y):
		var holder := _view.find_view_holder_for_adapter_position(item_position)
		var preview := holder.get_item_view() as Preview
		assert_vector(preview.custom_minimum_size).is_equal(Preview.BASE_SIZE * ui_scale)
		assert_object(preview.asset_thumbnail.texture).is_same(_cache.placeholder)
		var rect := _view.layout_manager.get_item_rect(
			item_position, _view.adapter.get_item_count(), _view.get_layout_viewport_size()
		)
		var minimum := preview.get_combined_minimum_size()
		assert_float(rect.size.x + 0.01).is_greater_equal(minimum.x)
		assert_float(rect.size.y + 0.01).is_greater_equal(minimum.y)
		assert_vector(preview.position).is_equal(rect.position)
		assert_vector(preview.size).is_equal(rect.size)
		assert_str(preview.button.theme_type_variation).is_equal("FlatButton")
