@tool
class_name RecyclerViewHolder
extends RefCounted
## Wraps an item's root Control and its current adapter position.
##
## Subclasses may cache child references. The holder does not parent, detach, or free its
## item view. When used by RecyclerView, the recycler owns that node; standalone callers
## must manage its lifetime themselves.

const NO_POSITION: int = -1

var _item_view: Control
var _binding_adapter_position: int = NO_POSITION


## The item view must be a live Control. Adapter creation validates it before use.
func _init(item_view: Control) -> void:
	_item_view = item_view


func get_item_view() -> Control:
	return _item_view


## Returns NO_POSITION before binding and after recycling.
## Read this at interaction time instead of capturing a position in a signal connection.
func get_binding_adapter_position() -> int:
	return _binding_adapter_position


## Indicates a binding assignment, not whether the item view is visible or alive.
func is_bound() -> bool:
	return _binding_adapter_position != NO_POSITION


## Adapter-owned bookkeeping; not a subclass hook.
func _set_binding_adapter_position(position: int) -> void:
	_binding_adapter_position = position
