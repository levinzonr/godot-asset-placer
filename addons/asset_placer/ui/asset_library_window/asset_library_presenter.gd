class_name AssetLibraryPresenter
extends RefCounted

signal assets_loaded(assets: Array[AssetResource])
signal asset_selection_change
signal show_filter_info(size: int)
signal show_sync_active(bool)
signal show_empty_view(type: EmptyType)

enum EmptyType { Search, Collection, All, None }

var library: AssetLibrary
var synchronizer: Synchronize

var _active_collections: Array[AssetCollection] = []
var _filtered_assets: Array[AssetResource] = []
var _current_query: String

var _asset_library: AssetLibrary:
	get:
		return AssetLibraryManager.get_asset_library()


func _init():
	synchronizer = Synchronize.instance


func on_ready():
	show_filter_info.emit(0)
	_asset_library.assets_changed.connect(_filter_by_collections_and_query)
	_filter_by_collections_and_query()
	synchronizer.sync_state_change.connect(func(v): show_sync_active.emit(v))


func add_folder(path: String):
	var new_folder := AssetFolder.new(path)
	_asset_library.add_folder(new_folder)


func on_query_change(query: String):
	_current_query = query
	_filter_by_collections_and_query()


func add_asset(path: String, folder_path: String):
	var tags: Array[int] = []
	for collection in _active_collections:
		tags.push_back(collection.id)

	var id = ResourceIdCompat.path_to_uid(path)
	assert(id, "Error getting id from path %s" % path)

	var existing := _asset_library.find_asset_by_uid(id)
	if existing:
		existing.add_tags(tags)
		_asset_library.update(existing)
	else:
		var new_asset := AssetResource.from_path(path, tags, folder_path)
		if new_asset:
			_asset_library.add_asset(new_asset)


func delete_asset(asset: AssetResource):
	_asset_library.remove_asset_by_id(asset.id)


func add_assets_or_folders(files: PackedStringArray):
	for file in files:
		if file.get_extension().is_empty():
			add_folder(file)
		else:
			add_asset(file, "")


func toggle_asset_collection(asset: AssetResource, collection: AssetCollection, add: bool):
	if add:
		asset.add_tag(collection.id)
	else:
		asset.remove_tag(collection.id)
	_asset_library.update_asset(asset)


func toggle_collection_filter(collection: AssetCollection, enabled: bool):
	if enabled:
		_active_collections.push_back(collection)
	else:
		_active_collections = _active_collections.filter(func(a): return a.id != collection.id)
	show_filter_info.emit(_active_collections.size())
	_filter_by_collections_and_query()


func _filter_by_collections_and_query():
	var filtered: Array[AssetResource] = []
	for asset in _asset_library.get_assets():
		var matches_query = asset.name.containsn(_current_query) || _current_query.is_empty()
		var belongs_to_collection = (
			asset.belongs_to_some_collection(_active_collections) || _active_collections.is_empty()
		)

		if matches_query and belongs_to_collection:
			filtered.push_back(asset)

	if filtered.is_empty():
		if _active_collections.is_empty() && _current_query.is_empty():
			show_empty_view.emit(EmptyType.All)
		elif not _active_collections.is_empty():
			show_empty_view.emit(EmptyType.Collection)
		else:
			show_empty_view.emit(EmptyType.Search)
	else:
		assets_loaded.emit(filtered)
		show_empty_view.emit(EmptyType.None)

	_filtered_assets = filtered


func sync():
	synchronizer.sync_all()
