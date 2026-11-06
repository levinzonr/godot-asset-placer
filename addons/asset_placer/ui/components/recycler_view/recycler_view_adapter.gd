@tool
class_name RecyclerViewAdapter
extends RefCounted
## Supplies data and item views without owning layout, scrolling, or node lifetime.
##
## Override get_item_count(), _create_view_holder(), and _bind_view_holder(). Use the
## public create/bind/recycle methods to preserve holder bookkeeping and validation.
## This initial contract supports a single view type and full dataset notifications.

## Emitted synchronously after the caller changes its data. Does not mutate data or holders.
signal data_set_changed

const ViewHolder = preload("recycler_view_holder.gd")


## Returns a non-negative item count from the adapter's current data.
func get_item_count() -> int:
	push_error("RecyclerViewAdapter.get_item_count() must be overridden.")
	return 0


## Creates an unbound holder whose root Control has no parent.
## Parent is context for creation only; mounting is the caller's responsibility.
## Returns null on a contract violation. This method never frees an item view.
func create_view_holder(parent: Control) -> ViewHolder:
	if not is_instance_valid(parent) or parent.is_queued_for_deletion():
		push_error("RecyclerViewAdapter.create_view_holder() requires a live parent.")
		return null

	var holder := _create_view_holder(parent)
	if not _has_usable_item_view(holder):
		return null
	if holder.get_item_view().get_parent() != null or holder.is_bound():
		push_error(
			"RecyclerViewAdapter._create_view_holder() must return an unattached, unbound holder."
		)
		return null
	return holder


## Fully binds current data to a mounted, ready item. Sets the position before the hook.
## Returns false on invalid input without changing the holder's previous binding.
## No awaiting, mounting, or deferred binding takes place here; RecyclerView will coordinate it.
func bind_view_holder(holder: ViewHolder, position: int) -> bool:
	if not _has_usable_item_view(holder):
		return false
	var item_view := holder.get_item_view()
	if not item_view.is_inside_tree() or not item_view.is_node_ready():
		push_error("RecyclerViewAdapter.bind_view_holder() requires a mounted, ready item view.")
		return false
	if position < 0 or position >= get_item_count():
		push_error(
			"RecyclerViewAdapter.bind_view_holder() position is outside the current item count."
		)
		return false

	holder._set_binding_adapter_position(position)
	_bind_view_holder(holder, position)
	return true


## Invalidates the position before calling the optional cleanup hook.
## Already-unbound holders are a no-op. Does not hide, detach, reset UI state, or free nodes.
func recycle_view_holder(holder: ViewHolder) -> void:
	if not _has_usable_item_view(holder) or not holder.is_bound():
		return
	holder._set_binding_adapter_position(ViewHolder.NO_POSITION)
	_on_view_recycled(holder)


## Call after changing the dataset. RecyclerView will schedule its own refresh.
func notify_data_set_changed() -> void:
	data_set_changed.emit()


## Return a new holder wrapping a live, unparented root Control; do not mount or bind it here.
func _create_view_holder(_parent: Control) -> ViewHolder:
	push_error("RecyclerViewAdapter._create_view_holder() must be overridden.")
	return null


## Item view is mounted and ready, and holder position already equals position.
## Replace all item-dependent state on every bind, including rebinds at the same position.
## Connect persistent UI signals once during creation, not on every bind.
func _bind_view_holder(_holder: ViewHolder, _position: int) -> void:
	push_error("RecyclerViewAdapter._bind_view_holder() must be overridden.")


## Optional cleanup for item-specific state, subscriptions, or asynchronous work.
## Position is already NO_POSITION. The item view is still alive; parenting is unchanged.
func _on_view_recycled(_holder: ViewHolder) -> void:
	pass


func _has_usable_item_view(holder: ViewHolder) -> bool:
	if holder == null or not is_instance_valid(holder.get_item_view()):
		push_error("RecyclerViewAdapter requires a holder with a live item view.")
		return false
	if holder.get_item_view().is_queued_for_deletion():
		push_error("RecyclerViewAdapter cannot use an item view queued for deletion.")
		return false
	return true
