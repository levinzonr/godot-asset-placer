@tool
extends "res://addons/asset_placer/ui/components/recycler_view/grid_layout_manager.gd"
## Preserves HFlowContainer's fixed-size, left-aligned previews and responsive wrapping.

var item_width: float = 150.0:
	set(value):
		item_width = maxf(value, 1.0)


func _init() -> void:
	item_height = 200.0


func get_content_size(item_count: int, viewport_size: Vector2) -> Vector2:
	_update_columns(viewport_size.x)
	return super.get_content_size(item_count, viewport_size)


func get_item_rect(position: int, item_count: int, viewport_size: Vector2) -> Rect2:
	_update_columns(viewport_size.x)
	return super.get_item_rect(position, item_count, viewport_size)


func get_visible_range(item_count: int, viewport_size: Vector2, scroll_offset: float) -> Vector2i:
	_update_columns(viewport_size.x)
	return super.get_visible_range(item_count, viewport_size, scroll_offset)


func _update_columns(viewport_width: float) -> void:
	span_count = maxi(1, floori((viewport_width + spacing.x) / (item_width + spacing.x)))


func _get_cell_width(viewport_width: float) -> float:
	return item_width if viewport_width > 0.0 else 0.0
