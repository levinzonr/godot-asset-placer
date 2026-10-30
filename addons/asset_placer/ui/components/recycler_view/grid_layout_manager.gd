@tool
class_name GridLayoutManager
extends "recycler_view_layout_manager.gd"
## Uniform vertical grid with an explicit column count and a fixed item height.
##
## Columns share the available viewport width after horizontal spacing is deducted.
## An incomplete final row keeps the same column widths. Spacing appears only between cells.
## A width that cannot accommodate positive-width cells produces an empty layout.
## Geometry queries use constant time and storage, independent of item count.

## Number of columns, clamped to at least one.
var span_count: int = 1:
	set(value):
		span_count = maxi(value, 1)

## Height of every cell in local UI units, clamped to at least one.
var item_height: float = 100.0:
	set(value):
		item_height = maxf(value, 1.0)

## Horizontal and vertical gaps in local UI units, clamped to non-negative values.
var spacing: Vector2 = Vector2.ZERO:
	set(value):
		spacing = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))


func get_content_size(item_count: int, viewport_size: Vector2) -> Vector2:
	if item_count <= 0 or _get_cell_width(viewport_size.x) <= 0.0:
		return Vector2.ZERO

	@warning_ignore("integer_division")
	var row_count := (item_count - 1) / span_count + 1
	var content_height := row_count * item_height + (row_count - 1) * spacing.y
	return Vector2(viewport_size.x, content_height)


func get_item_rect(position: int, item_count: int, viewport_size: Vector2) -> Rect2:
	if position < 0 or position >= item_count:
		return Rect2()

	var cell_width := _get_cell_width(viewport_size.x)
	if cell_width <= 0.0:
		return Rect2()

	@warning_ignore("integer_division")
	var row := position / span_count
	var column := position % span_count
	var origin := Vector2(column * (cell_width + spacing.x), row * (item_height + spacing.y))
	return Rect2(origin, Vector2(cell_width, item_height))


func get_visible_range(item_count: int, viewport_size: Vector2, scroll_offset: float) -> Vector2i:
	if item_count <= 0 or viewport_size.y <= 0.0 or _get_cell_width(viewport_size.x) <= 0.0:
		return Vector2i.ZERO

	var viewport_end := scroll_offset + viewport_size.y
	if viewport_end <= 0.0:
		return Vector2i.ZERO

	@warning_ignore("integer_division")
	var row_count := (item_count - 1) / span_count + 1
	var row_stride := item_height + spacing.y
	var first_row := maxi(0, floori(scroll_offset / row_stride))
	# An offset in the gap after a row must not include that row.
	if scroll_offset >= first_row * row_stride + item_height:
		first_row += 1
	var end_row := mini(row_count, ceili(viewport_end / row_stride))
	if first_row >= end_row:
		return Vector2i.ZERO

	return Vector2i(first_row * span_count, mini(item_count, end_row * span_count))


func _get_cell_width(viewport_width: float) -> float:
	return maxf(0.0, (viewport_width - (span_count - 1) * spacing.x) / span_count)
