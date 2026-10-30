@tool
extends "res://addons/asset_placer/ui/components/recycler_view/recycler_view.gd"
## Library-specific wiring; the reusable recycler remains independent of plugin settings.

signal asset_clicked(asset: AssetResource)
signal asset_context_requested(asset: AssetResource, control: Control)

const AssetAdapter = preload("asset_library_adapter.gd")
const AssetGrid = preload("asset_library_grid_layout_manager.gd")
const Preview = preload("res://addons/asset_placer/ui/components/asset_resource_preview.gd")

var _asset_adapter := AssetAdapter.new()
var _asset_grid := AssetGrid.new()
var _settings: AssetPlacerSettings = AssetPlacerSettings.default()
var _metrics_pending: bool = false


func _enter_tree() -> void:
	super._enter_tree()
	_queue_grid_metrics.call_deferred()


func _ready() -> void:
	super._ready()
	_asset_adapter.asset_clicked.connect(asset_clicked.emit)
	_asset_adapter.asset_context_requested.connect(asset_context_requested.emit)
	_asset_adapter.item_metrics_changed.connect(_queue_grid_metrics)
	adapter = _asset_adapter
	layout_manager = _asset_grid
	theme_changed.connect(_queue_grid_metrics)
	var repository := AssetPlacerSettingsRepository.instance
	if repository != null:
		repository.settings_changed.connect(apply_settings)
		apply_settings(repository.get_settings())
	else:
		apply_settings(_settings)


func _exit_tree() -> void:
	_metrics_pending = false
	super._exit_tree()


func set_assets(assets: Array[AssetResource]) -> void:
	_asset_adapter.submit_assets(assets)


func set_selected_asset(asset: AssetResource) -> void:
	_asset_adapter.selected_asset_id = asset.id if is_instance_valid(asset) else ""
	var positions := get_visible_range()
	for item_position in range(positions.x, positions.y):
		var holder := find_view_holder_for_adapter_position(item_position)
		if holder != null:
			var preview := holder.get_item_view() as Preview
			preview.select_not_signal(
				(
					is_instance_valid(preview.resource)
					and preview.resource.id == _asset_adapter.selected_asset_id
				)
			)


func apply_settings(settings: AssetPlacerSettings) -> void:
	_settings = settings
	_asset_adapter.settings = settings
	var positions := get_visible_range()
	for item_position in range(positions.x, positions.y):
		var holder := find_view_holder_for_adapter_position(item_position)
		if holder != null:
			(holder.get_item_view() as Preview).set_settings(settings)
	_queue_grid_metrics()


func _queue_grid_metrics() -> void:
	if _metrics_pending or not is_inside_tree():
		return
	_metrics_pending = true
	_update_grid_metrics.call_deferred()


func _update_grid_metrics() -> void:
	_metrics_pending = false
	if not is_inside_tree() or not is_node_ready():
		return
	# Small UI scales can be limited by the preview's label, thumbnail, and theme minima.
	var cell_size: Vector2 = Preview.BASE_SIZE * _settings.ui_scale
	var positions := get_visible_range()
	for item_position in range(positions.x, positions.y):
		var holder := find_view_holder_for_adapter_position(item_position)
		if holder != null:
			cell_size = cell_size.max(holder.get_item_view().get_combined_minimum_size())
	var spacing := Vector2(
		get_theme_constant("h_separation", "HFlowContainer"),
		get_theme_constant("v_separation", "HFlowContainer")
	)
	cell_size = cell_size.max(Vector2.ONE)
	# The recycler is vertical-only: keep one full scaled preview accessible in narrow docks.
	custom_minimum_size.x = ceilf(cell_size.x + get_v_scroll_bar().get_combined_minimum_size().x)
	if (
		not is_equal_approx(_asset_grid.item_width, cell_size.x)
		or not is_equal_approx(_asset_grid.item_height, cell_size.y)
		or not _asset_grid.spacing.is_equal_approx(spacing)
	):
		_asset_grid.item_width = cell_size.x
		_asset_grid.item_height = cell_size.y
		_asset_grid.spacing = spacing
		request_layout()
