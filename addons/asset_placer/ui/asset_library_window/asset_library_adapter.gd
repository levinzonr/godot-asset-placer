@tool
extends "res://addons/asset_placer/ui/components/recycler_view/recycler_view_adapter.gd"
## Adapts the complete filtered library result; holders never own asset identity.

signal asset_clicked(asset: AssetResource)
signal asset_context_requested(asset: AssetResource, control: Control)
signal item_metrics_changed

const Preview = preload("res://addons/asset_placer/ui/components/asset_resource_preview.gd")
const PREVIEW_SCENE = preload("res://addons/asset_placer/ui/components/asset_resource_preview.tscn")

var settings: AssetPlacerSettings = AssetPlacerSettings.default()
var selected_asset_id: String = ""

var _assets: Array[AssetResource] = []


func submit_assets(assets: Array[AssetResource]) -> void:
	_assets = assets.duplicate()
	notify_data_set_changed()


func get_item_count() -> int:
	return _assets.size()


func _create_view_holder(_parent: Control) -> ViewHolder:
	var preview := PREVIEW_SCENE.instantiate() as Preview
	var holder := ViewHolder.new(preview)
	preview.left_clicked.connect(_on_preview_left_clicked.bind(holder))
	preview.right_clicked.connect(_on_preview_right_clicked.bind(holder))
	preview.minimum_size_changed.connect(_on_preview_minimum_size_changed.bind(holder))
	return holder


func _bind_view_holder(holder: ViewHolder, position: int) -> void:
	var preview := holder.get_item_view() as Preview
	var asset := _assets[position]
	preview.set_settings(settings)
	preview.set_asset(asset)
	preview.set_meta("id", asset.id)
	preview.select_not_signal(asset.id == selected_asset_id)
	item_metrics_changed.emit()


func _on_view_recycled(holder: ViewHolder) -> void:
	(holder.get_item_view() as Preview).clear_asset()


func _on_preview_left_clicked(asset: AssetResource, holder: ViewHolder) -> void:
	if _is_current_assignment(asset, holder):
		asset_clicked.emit(asset)


func _on_preview_right_clicked(asset: AssetResource, holder: ViewHolder) -> void:
	if _is_current_assignment(asset, holder):
		asset_context_requested.emit(asset, holder.get_item_view())


func _on_preview_minimum_size_changed(holder: ViewHolder) -> void:
	if holder.is_bound():
		item_metrics_changed.emit()


func _is_current_assignment(asset: AssetResource, holder: ViewHolder) -> bool:
	var position := holder.get_binding_adapter_position()
	# Data can change before the deferred rebind. Do not route clicks through an old view.
	return position >= 0 and position < _assets.size() and _assets[position] == asset
