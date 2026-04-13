@tool
class_name AssetSortBy
extends RefCounted

## Class with sorting methods for AssetResource.
## All methods sort in ascending order by default.

enum SortMethod {
	Name,
	DateAdded,
	LastPlaced,
}


static func sort_by_name(left: AssetResource, right: AssetResource, ascending_order := true) -> bool:
	return not (ascending_order != (left.name.naturalnocasecmp_to(right.name) < 0))


static func sort_by_date_added(
	left: AssetResource, right: AssetResource, ascending_order := true
) -> bool:
	if ascending_order:
		return left.date_added < right.date_added
	return left.date_added > right.date_added



static func sort_by_last_placed(left: AssetResource, right: AssetResource, ascending_order := true):
	var es := APEditorSettingsManager.get_editor_settings()
	var dict := es.get_assets_time_placed()
	var left_val = dict.get(left.id, 0.0)
	var right_val = dict.get(right.id, 0.0)
	# if right_val == 0.0 and left_val == 0.0:
	# 	return false
	if ascending_order:
		return left_val > right_val
	return left_val < right_val

static func get_sort_function(method: SortMethod, ascending_order := true) -> Callable:
	var fun: Callable
	match method:
		SortMethod.Name:
			fun = sort_by_name.bind(ascending_order)
		SortMethod.DateAdded:
			fun = sort_by_date_added.bind(ascending_order)
		SortMethod.LastPlaced:
			fun = sort_by_last_placed.bind(ascending_order)
		_:
			push_warning("Chosen SortMethod %s is not supported." % method)
			fun = _default_sort

	return fun


## Do not sort by default.
static func _default_sort(left: AssetResource, right: AssetResource) -> bool:
	return false