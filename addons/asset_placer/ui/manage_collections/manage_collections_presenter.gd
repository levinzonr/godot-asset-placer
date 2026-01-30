class_name ManageCollectionsPresenter
extends RefCounted

signal assets_changed(assets: Array[AssetResource])
signal selection_changed(indices: PackedInt32Array, batch_mode: bool)
signal collections_changed(collections: Array[CollectionState], batch_mode: bool)

enum SelectMode { SINGLE, RANGE, MULTI }


class CollectionState:
	var collection: AssetCollection
	var assigned_count: int = 0
	var total_selected: int = 0

	func is_full() -> bool:
		return assigned_count == total_selected and total_selected > 0

	func is_partial() -> bool:
		return assigned_count > 0 and assigned_count < total_selected

	func is_available() -> bool:
		return assigned_count < total_selected or total_selected == 0

var _assets_repository: AssetsRepository
var _collections_repository: AssetCollectionRepository

var _assets: Array[AssetResource] = []
var _selected_indices: PackedInt32Array = []
var _batch_mode: bool = false
var _last_toggled_index: int = -1


func _init():
	_assets_repository = AssetsRepository.instance
	_collections_repository = AssetCollectionRepository.instance


func ready():
	_assets = _assets_repository.get_all_assets()
	if not _assets.is_empty():
		_selected_indices = PackedInt32Array([0])
		_last_toggled_index = 0
	_emit_assets()
	_emit_selection()
	_emit_collections()


func toggle_asset(index: int, mode: SelectMode):
	if index < 0 or index >= _assets.size():
		return

	match mode:
		SelectMode.RANGE:
			if _last_toggled_index >= 0:
				_select_range(_last_toggled_index, index)
			else:
				_selected_indices = PackedInt32Array([index])
				_last_toggled_index = index
				_emit_selection()
				_emit_collections()

		SelectMode.MULTI:
			_batch_mode = true
			var pos := _index_in_selection(index)
			if pos >= 0:
				_selected_indices.remove_at(pos)
			else:
				_selected_indices.push_back(index)
			_last_toggled_index = index
			_emit_selection()
			_emit_collections()

		SelectMode.SINGLE:
			_batch_mode = false
			_selected_indices = PackedInt32Array([index])
			_last_toggled_index = index
			_emit_selection()
			_emit_collections()


func select_all():
	if not _batch_mode:
		_batch_mode = true

	_selected_indices.clear()
	for i in _assets.size():
		_selected_indices.push_back(i)

	_emit_selection()
	_emit_collections()


func filter_assets(query: String):
	var all_assets := _assets_repository.get_all_assets()

	if query.is_empty():
		_assets = all_assets
	else:
		_assets = all_assets.filter(
			func(asset: AssetResource): return asset.name.containsn(query)
		)

	_selected_indices.clear()
	if not _assets.is_empty():
		_selected_indices = PackedInt32Array([0])
		_last_toggled_index = 0

	_emit_assets()
	_emit_selection()
	_emit_collections()


func set_primary_collection(collection: AssetCollection):
	for idx in _selected_indices:
		var asset := _assets[idx]
		var current_index := asset.tags.find(collection.id)
		if current_index > 0:
			asset.tags.remove_at(current_index)
			asset.tags.insert(0, collection.id)
			_assets_repository.update(asset)
	_emit_collections()


func add_to_collection(collection: AssetCollection):
	for idx in _selected_indices:
		var asset := _assets[idx]
		if not asset.tags.has(collection.id):
			asset.tags.push_back(collection.id)
			_assets_repository.update(asset)
	_emit_collections()


func remove_from_collection(collection: AssetCollection):
	for idx in _selected_indices:
		var asset := _assets[idx]
		asset.tags = asset.tags.filter(func(id): return id != collection.id)
		_assets_repository.update(asset)
	_emit_collections()


func _select_range(from_index: int, to_index: int):
	if not _batch_mode:
		_batch_mode = true

	var start_idx := mini(from_index, to_index)
	var end_idx := maxi(from_index, to_index)

	for i in range(start_idx, end_idx + 1):
		if _index_in_selection(i) < 0:
			_selected_indices.push_back(i)

	_last_toggled_index = to_index
	_emit_selection()
	_emit_collections()


func _index_in_selection(index: int) -> int:
	for i in _selected_indices.size():
		if _selected_indices[i] == index:
			return i
	return -1


func _emit_assets():
	assets_changed.emit(_assets)


func _emit_selection():
	selection_changed.emit(_selected_indices, _batch_mode)


func _emit_collections():
	var collections: Array[CollectionState] = []
	var all_collections := _collections_repository.get_collections()
	var total := _selected_indices.size()

	var collection_counts: Dictionary = {}
	for idx in _selected_indices:
		for tag in _assets[idx].tags:
			collection_counts[tag] = collection_counts.get(tag, 0) + 1

	var first_tags: Array[int] = []
	if total > 0:
		first_tags = _assets[_selected_indices[0]].tags

	for collection in all_collections:
		var cs := CollectionState.new()
		cs.collection = collection
		cs.assigned_count = collection_counts.get(collection.id, 0)
		cs.total_selected = total
		collections.push_back(cs)

	collections.sort_custom(
		func(a: CollectionState, b: CollectionState):
			var a_full := a.is_full()
			var b_full := b.is_full()
			if a_full != b_full:
				return a_full

			if a_full and b_full:
				var a_idx := first_tags.find(a.collection.id)
				var b_idx := first_tags.find(b.collection.id)
				return (a_idx if a_idx >= 0 else 9999) < (b_idx if b_idx >= 0 else 9999)

			var a_partial := a.is_partial()
			var b_partial := b.is_partial()
			if a_partial != b_partial:
				return a_partial

			return false
	)

	collections_changed.emit(collections, _batch_mode)
