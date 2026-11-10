extends GdUnitTestSuite

const LibraryRecycler = preload(
	"res://addons/asset_placer/ui/asset_library_window/asset_library_recycler_view.gd"
)
const LibraryAdapter = preload(
	"res://addons/asset_placer/ui/asset_library_window/asset_library_adapter.gd"
)
const LibraryGrid = preload(
	"res://addons/asset_placer/ui/asset_library_window/asset_library_grid_layout_manager.gd"
)
const Preview = preload("res://addons/asset_placer/ui/components/asset_resource_preview.gd")
const WINDOW_SCENE_PATH: String = "res://addons/asset_placer/ui/asset_library_window/asset_library_window.tscn"
const LIBRARY_SCROLL_PATH: String = "MainContent/PanelContainer2/VBoxContainer/MarginContainer/ScrollContainer"
const INITIAL_SIZE: Vector2 = Vector2(640, 420)
const SETTLE_FRAMES: int = 16
const EPSILON: float = 0.01

var _view: LibraryRecycler
var _flow: HFlowContainer
var _assets: Array[AssetResource] = []
var _theme: Theme
var _saved_settings: AssetPlacerSettingsRepository
var _saved_cache: ThumbnailCacheStore
var _saved_coordinator: ThumbnailGenerationCoordinator


func before_test() -> void:
	_saved_settings = AssetPlacerSettingsRepository.instance
	_saved_cache = ThumbnailCacheStore.instance
	_saved_coordinator = ThumbnailGenerationCoordinator.instance
	# Real previews, but no editor-only repository, disk cache, or renderer services.
	AssetPlacerSettingsRepository.instance = null
	ThumbnailCacheStore.instance = null
	ThumbnailGenerationCoordinator.instance = null
	_theme = Theme.new()
	_theme.set_constant("h_separation", "HFlowContainer", 9)
	_theme.set_constant("v_separation", "HFlowContainer", 13)
	_view = LibraryRecycler.new()
	_view.theme = _theme
	_view.size = INITIAL_SIZE


func after_test() -> void:
	if is_instance_valid(_flow):
		_flow.free()
	_flow = null
	if is_instance_valid(_view):
		_view.free()
	_view = null
	await _settle()
	AssetPlacerSettingsRepository.instance = _saved_settings
	ThumbnailCacheStore.instance = _saved_cache
	ThumbnailGenerationCoordinator.instance = _saved_coordinator
	_saved_settings = null
	_saved_cache = null
	_saved_coordinator = null
	_assets.clear()


func test_five_hundred_assets_keep_full_adapter_count_and_bounded_real_previews() -> void:
	await _mount()
	assert_bool(_view.adapter is LibraryAdapter).is_true()
	assert_bool(_view.layout_manager is LibraryGrid).is_true()
	assert_int(_view.adapter.get_item_count()).is_equal(500)
	assert_int(_view.get_active_view_holder_count()).is_greater(0)
	assert_int(_view.get_active_view_holder_count()).is_less(500)
	assert_object(_view.find_view_holder_for_adapter_position(499)).is_null()
	_assert_bounded_inventory()
	_assert_geometry()
	var initial_roots := _all_previews()
	_view.scroll_vertical = 10000
	await _settle()
	assert_int(_view.get_visible_range().x).is_greater(0)
	assert_int(_view.adapter.get_item_count()).is_equal(500)
	assert_bool(_all_previews().any(func(root: Preview): return initial_roots.has(root))).is_true()
	_assert_bounded_inventory()
	_assert_geometry()


func test_responsive_fixed_width_and_wrapping_match_hflow_at_actual_viewport_width() -> void:
	await _mount()
	_flow = HFlowContainer.new()
	_flow.theme = _theme
	add_child(_flow)
	for index in range(12):
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(_grid().item_width, _grid().item_height)
		_flow.add_child(cell)
	for width in [330.0, 493.0, 641.0, 956.0]:
		_view.size.x = width
		await _settle()
		var viewport := _view.get_layout_viewport_size()
		_flow.size = Vector2(viewport.x, 4000)
		await _settle()
		var columns := maxi(1, floori((viewport.x + 9.0) / (150.0 + 9.0)))
		assert_int(_grid().span_count).override_failure_message(_geometry_context()).is_equal(
			columns
		)
		assert_float(_grid().item_width).is_equal_approx(150.0, EPSILON)
		assert_float(viewport.x).is_equal_approx(
			_view.size.x - _view.get_v_scroll_bar().size.x, EPSILON
		)
		for index in range(12):
			var rect := _item_rect(index)
			(
				assert_vector(rect.position)
				. override_failure_message(_geometry_context(index))
				. is_equal((_flow.get_child(index) as Control).position)
			)
			assert_float(rect.size.x).is_equal_approx(150.0, EPSILON)
		_assert_geometry()
	for ui_scale: float in [1.0, 2.0]:
		_apply_scale(ui_scale)
		_view.size.x = 120.0
		await _settle()
		assert_int(_grid().span_count).is_equal(1)
		assert_float(_item_rect(0).size.x).is_equal_approx(150.0 * ui_scale, EPSILON)
		assert_float(_view.get_layout_viewport_size().x + EPSILON).is_greater_equal(
			_item_rect(0).end.x
		)


func test_hflow_theme_gaps_are_inherited_and_live_changes_update_grid() -> void:
	await _mount()
	assert_vector(_grid().spacing).is_equal(Vector2(9, 13))
	_theme.set_constant("h_separation", "HFlowContainer", 27)
	_theme.set_constant("v_separation", "HFlowContainer", 31)
	await _settle()
	assert_vector(_grid().spacing).is_equal(Vector2(27, 31))
	assert_float(_item_rect(1).position.x).is_equal_approx(_grid().item_width + 27.0, EPSILON)
	assert_float(_item_rect(_grid().span_count).position.y).is_equal_approx(
		_grid().item_height + 31.0, EPSILON
	)
	_assert_geometry()


func test_scales_point_two_one_and_two_use_baseline_and_actual_preview_minima() -> void:
	await _mount()
	assert_vector(Preview.BASE_SIZE).is_equal(Vector2(150, 200))
	for ui_scale in [0.2, 1.0, 2.0]:
		_apply_scale(ui_scale)
		await _settle()
		var baseline: Vector2 = Preview.BASE_SIZE * ui_scale
		var expected: Vector2 = baseline
		for preview in _visible_previews():
			assert_vector(preview.custom_minimum_size).is_equal(baseline)
			expected = expected.max(preview.get_combined_minimum_size())
		(
			assert_float(_grid().item_width)
			. override_failure_message(_geometry_context())
			. is_equal_approx(expected.x, EPSILON)
		)
		(
			assert_float(_grid().item_height)
			. override_failure_message(_geometry_context())
			. is_equal_approx(expected.y, EPSILON)
		)
		_assert_geometry()


func test_live_scale_two_to_point_two_shrinks_slots_without_overlapping_minimum_height() -> void:
	await _mount(500, 2.0)
	var large_height := _grid().item_height
	var large_width := _grid().item_width
	_apply_scale(0.2)
	await _settle()
	assert_float(_grid().item_height).override_failure_message(_geometry_context()).is_less(
		large_height
	)
	assert_float(_grid().item_width).override_failure_message(_geometry_context()).is_less(
		large_width
	)
	assert_int(_view.get_active_view_holder_count()).is_greater(_grid().span_count)
	for preview in _visible_previews():
		assert_vector(preview.custom_minimum_size).is_equal(Preview.BASE_SIZE * 0.2)
		(
			assert_bool(_grid().item_height + EPSILON >= preview.get_combined_minimum_size().y)
			. override_failure_message(_geometry_context())
			. is_true()
		)
	_assert_geometry()


func test_pooled_previews_receive_current_scale_when_reused() -> void:
	await _mount(500, 0.2)
	_apply_scale(2.0)
	await _settle()
	var pooled: Array[Preview] = []
	for preview in _all_previews():
		if not preview.visible:
			pooled.append(preview)
	assert_int(pooled.size()).is_greater(0)
	assert_int(_view.get_recycled_view_holder_count()).is_equal(pooled.size())
	for preview in pooled:
		_assert_cleared(preview)
	_apply_scale(1.0)
	_view.size = Vector2(1000, 900)
	await _settle()
	var reused := 0
	for preview in _visible_previews():
		if pooled.has(preview):
			reused += 1
			assert_vector(preview.custom_minimum_size).is_equal(Preview.BASE_SIZE)
	assert_int(reused).is_greater(0)
	_assert_geometry()


func test_offscreen_selection_is_restored_when_scrolling_away_and_back() -> void:
	await _mount()
	var selected := _assets[420]
	_view.set_selected_asset(selected)
	assert_object(_view.find_view_holder_for_adapter_position(420)).is_null()
	_assert_selected_visible("")
	await _scroll_to(420)
	assert_bool(_preview_at(420).button.button_pressed).is_true()
	_assert_selected_visible(selected.id)
	_view.scroll_vertical = 0
	await _settle()
	assert_object(_view.find_view_holder_for_adapter_position(420)).is_null()
	await _scroll_to(420)
	assert_bool(_preview_at(420).button.button_pressed).is_true()
	_assert_selected_visible(selected.id)


func test_select_and_deselect_update_buttons_without_rebinding_thumbnails_or_clicks() -> void:
	await _mount()
	var preview := _preview_at(0)
	var thumbnail: AssetThumbnail = preview.asset_thumbnail
	var texture := GradientTexture2D.new()
	thumbnail.texture = texture
	thumbnail.last_time_modified = 12345
	var clicks: Array[AssetResource] = []
	_view.asset_clicked.connect(func(asset: AssetResource): clicks.append(asset))
	_view.set_selected_asset(_assets[0])
	assert_bool(preview.button.button_pressed).is_true()
	_view.set_selected_asset(_assets[1])
	assert_bool(preview.button.button_pressed).is_false()
	assert_bool(_preview_at(1).button.button_pressed).is_true()
	_view.set_selected_asset(null)
	await _settle()
	_assert_selected_visible("")
	assert_object(_preview_at(0)).is_same(preview)
	assert_object(thumbnail._resource).is_same(_assets[0])
	assert_object(thumbnail.texture).is_same(texture)
	assert_int(thumbnail.last_time_modified).is_equal(12345)
	assert_array(clicks).is_empty()


func test_selected_id_survives_sorted_and_replaced_asset_models() -> void:
	await _mount(12)
	var original := _assets[3]
	_view.set_selected_asset(original)
	_assets.reverse()
	_view.set_assets(_assets)
	await _settle()
	await _scroll_to(8)
	assert_object(_preview_at(8).resource).is_same(original)
	assert_bool(_preview_at(8).button.button_pressed).is_true()
	var replacement := AssetResource.new(original.id, "Replacement model")
	var replaced: Array[AssetResource] = [replacement, _assets[0], _assets[1]]
	_view.set_assets(replaced)
	await _settle()
	_view.scroll_vertical = 0
	await _settle()
	assert_object(_preview_at(0).resource).is_same(replacement)
	assert_str(_preview_at(0).label.text).is_equal("Replacement model")
	assert_bool(_preview_at(0).button.button_pressed).is_true()
	_assert_selected_visible(original.id)


func test_empty_submission_clears_recycled_previews_and_stops_thumbnail_processing() -> void:
	await _mount()
	_view.set_selected_asset(_assets[0])
	var roots := _all_previews()
	_view.set_assets([])
	await _settle()
	assert_int(_view.adapter.get_item_count()).is_zero()
	assert_int(_view.get_active_view_holder_count()).is_zero()
	assert_vector(_view.get_visible_range()).is_equal(Vector2i.ZERO)
	assert_vector(_view.get_content_size()).is_equal(Vector2.ZERO)
	assert_int(_view.scroll_vertical).is_zero()
	assert_bool(_view.is_processing()).is_false()
	assert_int(_view.get_recycled_view_holder_count()).is_greater(0)
	for preview in roots:
		if is_instance_valid(preview):
			_assert_cleared(preview)
	assert_object(_view.find_view_holder_for_adapter_position(0)).is_null()


func test_click_signals_use_current_asset_and_preview_control_after_holder_reuse() -> void:
	await _mount()
	var original_roots := _visible_previews()
	var clicks: Array[AssetResource] = []
	var context_assets: Array[AssetResource] = []
	var context_controls: Array[Control] = []
	_view.asset_clicked.connect(func(asset: AssetResource): clicks.append(asset))
	_view.asset_context_requested.connect(
		func(asset: AssetResource, control: Control):
			context_assets.append(asset)
			context_controls.append(control)
	)
	_view.scroll_vertical = 10000
	await _settle()
	var reused: Preview
	for preview in _visible_previews():
		if original_roots.has(preview):
			reused = preview
			break
	assert_object(reused).is_not_null()
	if reused == null:
		return
	var position := _view.get_visible_range().x + _visible_previews().find(reused)
	assert_object(reused.resource).is_same(_assets[position])
	reused.button.button_pressed = true
	reused._gui_input(_right_click())
	assert_array(clicks).contains_exactly([_assets[position]])
	assert_array(context_assets).contains_exactly([_assets[position]])
	assert_array(context_controls).contains_exactly([reused])
	assert_int(reused.left_clicked.get_connections().size()).is_equal(1)
	assert_int(reused.right_clicked.get_connections().size()).is_equal(1)


func test_stale_clicks_between_submission_and_deferred_bind_are_rejected() -> void:
	await _mount()
	var preview := _preview_at(0)
	var previous := preview.resource
	var clicks: Array[AssetResource] = []
	var contexts: Array[AssetResource] = []
	_view.asset_clicked.connect(func(asset: AssetResource): clicks.append(asset))
	_view.asset_context_requested.connect(
		func(asset: AssetResource, _control: Control): contexts.append(asset)
	)
	var replacement := AssetResource.new(previous.id, "New instance with same ID")
	var replaced: Array[AssetResource] = [replacement]
	_view.set_assets(replaced)
	assert_object(preview.resource).is_same(previous)
	preview.button.button_pressed = true
	preview._gui_input(_right_click())
	assert_array(clicks).is_empty()
	assert_array(contexts).is_empty()
	await _settle()
	assert_object(_preview_at(0)).is_same(preview)
	assert_object(preview.resource).is_same(replacement)
	preview.button.button_pressed = true
	preview._gui_input(_right_click())
	assert_array(clicks).contains_exactly([replacement])
	assert_array(contexts).contains_exactly([replacement])
	_view.set_assets([])
	preview.button.button_pressed = false
	preview._gui_input(_right_click())
	assert_int(clicks.size()).is_equal(1)
	assert_int(contexts.size()).is_equal(1)
	await _settle()


func test_clipping_plain_content_extent_and_theme_respect_last_partial_row() -> void:
	var panel := StyleBoxFlat.new()
	panel.content_margin_left = 7.0
	panel.content_margin_right = 11.0
	panel.content_margin_top = 5.0
	panel.content_margin_bottom = 13.0
	_theme.set_stylebox("panel", "ScrollContainer", panel)
	await _mount(17)
	assert_bool(_view.clip_contents).is_true()
	assert_int(_view.horizontal_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_DISABLED)
	assert_int(_view.vertical_scroll_mode).is_equal(ScrollContainer.SCROLL_MODE_SHOW_ALWAYS)
	assert_vector(_view.get_theme_stylebox("panel").get_minimum_size()).is_equal(Vector2.ZERO)
	var content := _view.get_node("Content") as Control
	assert_str(content.get_class()).is_equal("Control")
	assert_int(content.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	var rows := ceili(17.0 / _grid().span_count)
	var height := rows * _grid().item_height + (rows - 1) * _grid().spacing.y
	assert_float(_view.get_content_size().y).is_equal_approx(height, EPSILON)
	assert_vector(content.custom_minimum_size).is_equal(Vector2(0, ceilf(height)))
	assert_float(_item_rect(16).end.y).is_equal_approx(height, EPSILON)
	assert_float(_view.get_content_size().x).is_equal_approx(
		_view.get_layout_viewport_size().x, EPSILON
	)
	_view.scroll_vertical = 100000
	await _settle()
	assert_object(_view.find_view_holder_for_adapter_position(16)).is_not_null()
	assert_float(_view.get_v_scroll_bar().value).is_equal_approx(
		height - _view.get_v_scroll_bar().page, EPSILON
	)
	_assert_geometry()


func test_window_scene_scroll_container_uses_library_recycler_without_hflow_child() -> void:
	# Loading PackedScene compiles editor-only window/options services; inspect text instead.
	var scene_text := FileAccess.get_file_as_string(WINDOW_SCENE_PATH)
	assert_str(scene_text).is_not_empty()
	var resource_pattern := RegEx.new()
	(
		assert_int(
			resource_pattern.compile(
				(
					"(?m)^\\[ext_resource\\s+"
					+ '(?=[^\\r\\n]*\\btype="Script")'
					+ '(?=[^\\r\\n]*\\bpath="res://addons/asset_placer/ui/asset_library_window/'
					+ 'asset_library_recycler_view\\.gd")'
					+ '[^\\r\\n]*\\bid="([^"]+)"[^\\r\\n]*\\]'
				)
			)
		)
		. is_equal(OK)
	)
	var resources := resource_pattern.search_all(scene_text)
	assert_int(resources.size()).is_equal(1)
	if resources.size() != 1:
		return
	var script_id := resources[0].get_string(1)
	var node_pattern := RegEx.new()
	(
		assert_int(node_pattern.compile("(?ms)^\\[node ([^\\r\\n]+)\\]\\r?\\n(.*?)(?=^\\[|\\z)"))
		. is_equal(OK)
	)
	var name_pattern := RegEx.new()
	var parent_pattern := RegEx.new()
	var type_pattern := RegEx.new()
	var script_pattern := RegEx.new()
	assert_int(name_pattern.compile('\\bname="([^"]+)"')).is_equal(OK)
	assert_int(parent_pattern.compile('\\bparent="([^"]+)"')).is_equal(OK)
	assert_int(type_pattern.compile('\\btype="([^"]+)"')).is_equal(OK)
	(
		assert_int(script_pattern.compile('(?m)^script\\s*=\\s*ExtResource\\("([^"]+)"\\)\\s*$'))
		. is_equal(OK)
	)
	var recycler_count := 0
	for section in node_pattern.search_all(scene_text):
		var header := section.get_string(1)
		var node_name := name_pattern.search(header)
		var parent := parent_pattern.search(header)
		if node_name == null or parent == null:
			continue
		var parent_path := parent.get_string(1).trim_prefix("./")
		var path := "%s/%s" % [parent_path, node_name.get_string(1)]
		var node_type := type_pattern.search(header)
		if path == LIBRARY_SCROLL_PATH:
			recycler_count += 1
			assert_object(node_type).is_not_null()
			if node_type != null:
				assert_str(node_type.get_string(1)).is_equal("ScrollContainer")
			var script := script_pattern.search(section.get_string(2))
			(
				assert_object(script)
				. override_failure_message(
					"Library ScrollContainer must assign the recycler script: %s" % header
				)
				. is_not_null()
			)
			if script != null:
				assert_str(script.get_string(1)).is_equal(script_id)
		if parent_path == LIBRARY_SCROLL_PATH or parent_path.begins_with(LIBRARY_SCROLL_PATH + "/"):
			(
				assert_bool(node_type != null and node_type.get_string(1) == "HFlowContainer")
				. override_failure_message(
					"Legacy HFlow container remains below the recycler: %s" % path
				)
				. is_false()
			)
			(
				assert_bool(node_name.get_string(1) in ["GridContainer", "HFlowGrid"])
				. override_failure_message(
					"Legacy grid child remains below the recycler: %s" % path
				)
				. is_false()
			)
	(
		assert_int(recycler_count)
		. override_failure_message(
			"Expected exactly one library ScrollContainer at %s" % LIBRARY_SCROLL_PATH
		)
		. is_equal(1)
	)


func _mount(item_count: int = 500, ui_scale: float = 1.0) -> void:
	_assets = _make_assets(item_count)
	_view.set_assets(_assets)
	_apply_scale(ui_scale)
	add_child(_view)
	await _settle()


func _make_assets(count: int) -> Array[AssetResource]:
	var assets: Array[AssetResource] = []
	for index in range(count):
		assets.append(
			AssetResource.new(
				"res://nonexistent_library_recycler_test_%04d.tscn" % index, "Asset %04d" % index
			)
		)
	return assets


func _apply_scale(ui_scale: float) -> void:
	var settings := AssetPlacerSettings.default()
	settings.ui_scale = ui_scale
	_view.apply_settings(settings)


func _grid() -> LibraryGrid:
	return _view.layout_manager as LibraryGrid


func _item_rect(position: int) -> Rect2:
	return _view.layout_manager.get_item_rect(
		position, _view.adapter.get_item_count(), _view.get_layout_viewport_size()
	)


func _preview_at(position: int) -> Preview:
	var holder := _view.find_view_holder_for_adapter_position(position)
	assert_object(holder).override_failure_message(_geometry_context(position)).is_not_null()
	return holder.get_item_view() as Preview if holder != null else null


func _visible_previews() -> Array[Preview]:
	var previews: Array[Preview] = []
	var visible := _view.get_visible_range()
	for position in range(visible.x, visible.y):
		var preview := _preview_at(position)
		if preview != null:
			previews.append(preview)
	return previews


func _all_previews() -> Array[Preview]:
	var previews: Array[Preview] = []
	for child in _view.get_node("Content").get_children():
		assert_bool(child is Preview).is_true()
		if child is Preview:
			previews.append(child)
	return previews


func _scroll_to(position: int) -> void:
	_view.scroll_vertical = floori(_item_rect(position).position.y)
	await _settle()


func _settle() -> void:
	for frame in range(SETTLE_FRAMES):
		await get_tree().process_frame


func _right_click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	return event


func _assert_selected_visible(selected_id: String) -> void:
	for preview in _visible_previews():
		(
			assert_bool(preview.button.button_pressed)
			. override_failure_message(
				(
					"selected=%s preview=%s; %s"
					% [selected_id, preview.resource.id, _geometry_context()]
				)
			)
			. is_equal(preview.resource.id == selected_id)
		)


func _assert_cleared(preview: Preview) -> void:
	assert_bool(preview.visible).is_false()
	assert_object(preview.resource).is_null()
	assert_str(preview.label.text).is_empty()
	assert_bool(preview.button.button_pressed).is_false()
	assert_bool(preview.button.disabled).is_true()
	assert_bool(preview.has_meta("id")).is_false()
	var thumbnail: AssetThumbnail = preview.asset_thumbnail
	assert_object(thumbnail._resource).is_null()
	assert_object(thumbnail.texture).is_null()
	assert_str(thumbnail._thumbnail_identifier).is_empty()
	assert_bool(thumbnail.is_processing()).is_false()


func _assert_bounded_inventory() -> void:
	var visible := _view.get_visible_range()
	var row_bound := (
		ceili(_view.get_layout_viewport_size().y / (_grid().item_height + _grid().spacing.y)) + 1
	)
	var active_bound := row_bound * _grid().span_count
	(
		assert_int(_view.get_active_view_holder_count())
		. override_failure_message(_geometry_context())
		. is_equal(visible.y - visible.x)
	)
	(
		assert_bool(_view.get_active_view_holder_count() <= active_bound)
		. override_failure_message(_geometry_context())
		. is_true()
	)
	(
		assert_bool(_all_previews().size() <= active_bound + _view.recycled_pool_capacity)
		. override_failure_message(_geometry_context())
		. is_true()
	)
	assert_int(_all_previews().size()).is_equal(
		_view.get_active_view_holder_count() + _view.get_recycled_view_holder_count()
	)


func _assert_geometry() -> void:
	var visible := _view.get_visible_range()
	var rectangles: Array[Rect2] = []
	for position in range(visible.x, visible.y):
		var preview := _preview_at(position)
		if preview == null:
			continue
		var expected := _item_rect(position)
		var context := _geometry_context(position)
		assert_vector(preview.position).override_failure_message(context).is_equal(
			expected.position
		)
		assert_vector(preview.size).override_failure_message(context).is_equal(expected.size)
		var minimum := preview.get_combined_minimum_size()
		(
			assert_bool(expected.size.x + EPSILON >= minimum.x)
			. override_failure_message(context)
			. is_true()
		)
		(
			assert_bool(expected.size.y + EPSILON >= minimum.y)
			. override_failure_message(context)
			. is_true()
		)
		assert_bool(preview.visible).is_true()
		for previous in rectangles:
			(
				assert_bool(preview.get_rect().intersects(previous))
				. override_failure_message(
					(
						"Overlapping preview rectangles %s / %s; %s"
						% [preview.get_rect(), previous, context]
					)
				)
				. is_false()
			)
		rectangles.append(preview.get_rect())


func _geometry_context(position: int = -1) -> String:
	var details := (
		"items=%s visible=%s active=%s pooled=%s viewport=%s scroll=%s cell=%s gaps=%s columns=%s"
		% [
			_view.adapter.get_item_count(),
			_view.get_visible_range(),
			_view.get_active_view_holder_count(),
			_view.get_recycled_view_holder_count(),
			_view.get_layout_viewport_size(),
			_view.scroll_vertical,
			Vector2(_grid().item_width, _grid().item_height),
			_grid().spacing,
			_grid().span_count,
		]
	)
	if position >= 0:
		details += " position=%s slot=%s" % [position, _item_rect(position)]
		var holder := _view.find_view_holder_for_adapter_position(position)
		if holder != null:
			var preview := holder.get_item_view()
			details += (
				" actual=%s minimum=%s" % [preview.get_rect(), preview.get_combined_minimum_size()]
			)
	return details
