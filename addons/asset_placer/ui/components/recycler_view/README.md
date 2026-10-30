# Recycler view component

An independent, reusable GDScript recycler component, built incrementally. A native
scrolling control now connects layout geometry, adapters, view holders, and a bounded
reuse pool. There is no Asset Placer integration. The source has no dependency on
Asset Placer or gdUnit4.

## RecyclerView

`RecyclerView` extends `ScrollContainer`. Configure an adapter and a layout manager,
then add it to your UI. No separate scene or EditorPlugin registration is required.
For example, using the `TextAdapter` shown below:

```gdscript
var data := TextAdapter.new()
data.items = ["One", "Two", "Three"]

var grid := GridLayoutManager.new()
grid.span_count = 3
grid.item_height = 100.0
grid.spacing = Vector2(10.0, 8.0)

var recycler := RecyclerView.new()
recycler.size = Vector2(320.0, 200.0)
recycler.adapter = data
recycler.layout_manager = grid
add_child(recycler)
```

### Behavior

- Configuration may happen before entering the scene tree. Items are created and
  bound only once the recycler and its native scroll area are ready.
- Only items intersecting the viewport are active; there is no overscan. Scrolls
  keep overlapping holders without rebinding them, recycle outgoing holders first,
  and bind reused or newly created holders directly at the destination positions.
- The plain internal content `Control` publishes the full content height. Native
  scrolling handles clipping, scrollbar ranges, and clamping after data shrink.
  Item rectangles stay in content coordinates; they are not manually scrolled.
- `recycled_pool_capacity` defaults to 12 and is clamped to zero or greater. Outgoing
  holders can be reused within a pass even at capacity zero. The idle pool is trimmed
  afterward, and excess views are hidden and queued for deletion.
- Pooled roots remain hidden and parented under the content node, so node lifetime
  remains owned by the recycler. **Hiding does not stop processing**: adapters should
  stop item-specific work in their recycling hook and restore it when binding.
- Replacing the adapter disconnects its notifications and disposes its active and
  pooled views. Holders are never shared between adapters. Removing the recycler
  from the tree also clears views; re-adding it builds fresh current assignments.
- Valid factory results are owned by the recycler. Callers must not free/reparent
  its item views or add their own children to its managed content node.

### Refresh and inspection

Refreshes are coalesced to the next process frame, not performed synchronously.
Changing content height requires native container sorting before items can be laid
out, so initial layout or data shrink may take additional frames to settle.

- Modify data, then call `adapter.notify_data_set_changed()`: current active items
  are fully rebound using the latest data. Several notifications before a refresh
  coalesce into one rebind pass.
- Change grid configuration, then call `recycler.request_layout()`. Resize, theme,
  and scroll changes request layout automatically; unchanged assignments need not
  rebind just because their rectangles change.
- `get_layout_viewport_size()` returns the allocated native viewport, excluding the
  vertical scrollbar. `get_content_size()` returns the last calculated full extent.
- `get_visible_range()` returns the applied half-open range. Use
  `find_view_holder_for_adapter_position(position)` for an active holder, or `null`
  for an offscreen position. Holders may be reassigned on the next refresh.
- `get_active_view_holder_count()` and `get_recycled_view_holder_count()` expose the
  current inventories for inspection.

Use inherited `scroll_vertical` or the native vertical scrollbar for programmatic
scrolling. Visibility calculations use the scrollbar's full-precision value, not
an integer-rounded offset.

### Deliberate first-increment limits

Vertical scrolling is enabled with an **always-visible scrollbar**, and horizontal
scrolling is disabled. Keep those modes unchanged for now. The stable width avoids
scrollbar visibility feeding back into grid geometry; automatic visibility is deferred.
The scroll panel has no content margins; put decorative padding or borders outside
this control. Native scrollbar theming is still supported.

Item roots must fit their grid cells and must not be top-level controls. The recycler
sets their root anchors, position, and size; containers may arrange their interior.
Control minimum sizes can still exceed the assigned cell, so item scenes must constrain
content appropriately. Keyboard navigation to uninstantiated items, automatic column
counts, animations, prefetch, and shared/multiple-type pools are not implemented.

## Layout contract

`RecyclerViewLayoutManager` extends `RefCounted`. Subclasses override:

- `get_content_size(item_count, viewport_size) -> Vector2`
- `get_item_rect(position, item_count, viewport_size) -> Rect2`
- `get_visible_range(item_count, viewport_size, scroll_offset) -> Vector2i`

This initial contract describes vertically scrolling, row-major layouts. Inputs are
local UI units and zero-based adapter positions. Rectangles are in content coordinates,
not shifted by scrolling. The viewport starts at `(0, scroll_offset)`.

Visible ranges are half-open: `(3, 9)` means positions 3 through 8. Only positive-area
intersection counts; touching an edge does not make an item visible. Empty ranges
are always `(0, 0)`. There is no overscan, and layout queries do not clamp scroll
offsets. `RecyclerView` delegates scrolling and clamping to its native ScrollContainer.

## Uniform grid

```gdscript
var layout := GridLayoutManager.new()
layout.span_count = 3
layout.item_height = 100.0
layout.spacing = Vector2(10.0, 8.0)

var viewport := Vector2(320.0, 200.0)
layout.get_content_size(10, viewport)           # Vector2(320, 424)
layout.get_item_rect(4, 10, viewport)           # Rect2(110, 108, 100, 100)
layout.get_visible_range(10, viewport, 108.0)   # Vector2i(3, 9)
```

- Columns divide viewport width equally after horizontal gaps are deducted.
- All cells have the configured height. An incomplete row does not stretch its cells.
- Spacing occurs only between cells, with no leading or trailing gap.
- Queries use constant time and storage; no per-item table or nodes are allocated.
- Geometry is recalculated from current inputs and configuration on every query.

### Boundary behavior

- `span_count` defaults to 1 and is clamped to at least 1.
- `item_height` defaults to 100 and is clamped to at least 1 local UI unit.
- `spacing` defaults to zero; each component is clamped to non-negative values.
- Non-positive item counts produce empty geometry.
- Invalid item positions return `Rect2()`.
- If viewport width minus all horizontal gaps is non-positive, all queries return
  empty geometry. There is no horizontal overflow or automatic reduction in columns.
- Non-positive viewport heights produce no visible items, but do not change content
  size or item rectangles when width is valid.
- Viewports before or after the content return only their actual intersections,
  possibly none. A viewport wholly inside a row gap has no visible items.

Padding, automatic column counts, variable item sizes, spans, and horizontal scrolling
are intentionally outside this increment.

## View holder

`RecyclerViewHolder.new(item_view)` wraps a root `Control`. Subclass it to cache
child references if useful.

- `get_item_view()` returns the root control.
- `get_binding_adapter_position()` returns the current zero-based adapter position,
  or `RecyclerViewHolder.NO_POSITION` (`-1`) before binding and after recycling.
- `is_bound()` indicates an assignment, not visibility or node validity.

The adapter maintains position bookkeeping. UI signal handlers should read the
current position at interaction time rather than capture the creation-time index.
A position is not a stable item identity; adapters remain responsible for cancelling
or guarding item-specific asynchronous work on rebind and recycle.

A holder does **not** own its control's lifetime: releasing the holder does not free
or detach the node. `RecyclerView` takes that responsibility for items it creates;
standalone callers of the adapter API must manage the nodes themselves. `Node.owner`
is not used for this purpose.

## Adapter

Subclass `RecyclerViewAdapter` and implement `get_item_count()`,
`_create_view_holder(parent)`, and `_bind_view_holder(holder, position)`. The optional
`_on_view_recycled(holder)` hook can clean up item-specific state and work.

```gdscript
class TextAdapter extends RecyclerViewAdapter:
    var items: Array[String] = []

    func get_item_count() -> int:
        return items.size()

    func _create_view_holder(_parent: Control) -> RecyclerViewHolder:
        return RecyclerViewHolder.new(Label.new())

    func _bind_view_holder(holder: RecyclerViewHolder, position: int) -> void:
        var label: Label = holder.get_item_view()
        label.text = items[position]
```

Call the public lifecycle methods, not the hooks:

1. `create_view_holder(parent)` returns an unattached, unbound holder. The parent is
   creation context, not an instruction to mount the item. The factory must return a
   live control that is not queued for deletion. Invalid creation returns `null`
   and reports an error; no view is automatically freed on a factory violation.
2. Mount and size the root control. **Wait for readiness when necessary**; parenting
   beneath an off-tree parent is not sufficient. There is no deferred binding here.
3. `bind_view_holder(holder, position)` checks that the view is mounted and ready and
   the position is in the current item count. It updates the holder's position before
   the hook, so `@onready` children and position are available during binding. Invalid
   input reports an error and returns `false`, leaving the previous binding unchanged.
4. `recycle_view_holder(holder)` clears the position **before** calling the cleanup
   hook. Recycling an already-unbound holder is a no-op. It does not hide, detach,
   reset UI state, or free the view. A recycled holder can be bound again.

Binding always means a full bind, even at the same position. The adapter must replace
all item-dependent UI state and cancel or supersede previous work. Connect persistent
UI signals once during creation, not during every bind. `_ready()` is initialization,
not a rebind callback; reusing a node does not normally run it again.

After changing adapter data, call `notify_data_set_changed()`. It emits the
`data_set_changed` signal synchronously once per call. The adapter does not change
data, invalidate existing holder positions, or rebind anything itself; `RecyclerView`
listens and schedules its refresh. Standalone users of the adapter API must refresh
or recycle affected holders before using old assignments with changed data.

This increment supports one homogeneous view type. Stable IDs, binding generations,
incremental notifications, diffing, and shared/multiple-type pools are deferred.

## Tests

Tests live separately in the repository's `tests/recycler_view/` source set, not in
this addon directory. See `tests/README.md` for the gdUnit4 command.
