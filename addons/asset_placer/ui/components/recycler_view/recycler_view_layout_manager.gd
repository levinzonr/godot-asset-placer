@tool
class_name RecyclerViewLayoutManager
extends RefCounted
## Geometry contract for a vertically scrolling, row-major recycler layout.
##
## Implementations calculate geometry without creating nodes or reading adapter data.
## All positions are zero-based adapter positions; all rectangles use content coordinates.
## Override all three methods. Virtual stubs keep this source compatible with Godot 4.3.


## Returns the full content extent, not just the visible portion.
## Non-positive item counts produce an empty layout. Viewport height does not limit content height.
func get_content_size(_item_count: int, _viewport_size: Vector2) -> Vector2:
	push_error("RecyclerViewLayoutManager.get_content_size() must be overridden.")
	return Vector2.ZERO


## Returns the rectangle for a position, or an empty rectangle for an invalid position.
func get_item_rect(_position: int, _item_count: int, _viewport_size: Vector2) -> Rect2:
	push_error("RecyclerViewLayoutManager.get_item_rect() must be overridden.")
	return Rect2()


## Returns intersecting adapter positions as [code][first, end)[/code].
## A rectangle touching only a viewport edge is not visible. Empty results are [code](0, 0)[/code].
## Scroll offsets are queried as supplied, not clamped. There is no overscan.
func get_visible_range(
	_item_count: int, _viewport_size: Vector2, _scroll_offset: float
) -> Vector2i:
	push_error("RecyclerViewLayoutManager.get_visible_range() must be overridden.")
	return Vector2i.ZERO
