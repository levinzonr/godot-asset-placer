@tool
class_name AssetSortBy
extends RefCounted

## Class with sorting methods for AssetResource.
## All methods sort in ascending order by default.

enum SortMethod {
	Name,
	LastPlaced,
	LastSaved,
	DateAdded,
}


static func sort_by_name(left: AssetResource, right: AssetResource) -> bool:
	return left.name.naturalcasecmp_to(right.name) < 0


static func sort_by_date_added(left: AssetResource, right: AssetResource):
	return left.date_added < right.date_added


static func get_sort_function(method: SortMethod, ascending_order := true) -> Callable:
	var fun: Callable
	match method:
		SortMethod.Name:
			fun = sort_by_name
		SortMethod.DateAdded:
			fun = sort_by_date_added
		_:
			push_warning("Chosen SortMethod %s is not supported." % method)
			fun = _default_sort

	if not ascending_order:
		return func(left, right): return not fun.call(left, right)

	return fun


## Do not sort by default.
static func _default_sort(left: AssetResource, right: AssetResource) -> bool:
	return false