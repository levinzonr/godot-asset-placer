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


func _init():
	synchronizer = Synchronize.instance


func on_ready():
	show_filter_info.emit(0)
	AssetLibraryManager.get_asset_library().assets_changed.connect(_filter_by_collections_and_query)
	_filter_by_collections_and_query()
	synchronizer.sync_state_change.connect(func(v): show_sync_active.emit(v))


func add_asset_folder(path: String):
	AssetLibraryManager.get_asset_library().add_folder(path)
	var dir_access := DirAccess.open(path)
	for file in dir_access.get_files():
		add_asset(path.path_join(file), path)


func on_query_change(query: String):
	_current_query = query
	_filter_by_collections_and_query()


func add_asset(path: String, folder_path: String):
	var tags: Array[int] = []
	for collection in _active_collections:
		tags.push_back(collection.id)

	var id = ResourceIdCompat.path_to_uid(path)
	if !id:
		push_error("Error getting id from path %s" % path)
		return

	var lib := AssetLibraryManager.get_asset_library()

	var existing = lib.find_asset_by_uid(id)
	if existing:
		var new_tags: Array[int] = []
		for tag in tags:
			if tag not in existing.tags:
				new_tags.push_back(tag)

		existing.tags.append_array(new_tags)
		lib.update(existing)
	else:
		lib.add_asset(path, tags, folder_path)


func delete_asset(asset: AssetResource):
	AssetLibraryManager.get_asset_library().remove_asset_by_id(asset.id)


func add_assets_or_folders(files: PackedStringArray):
	for file in files:
		if file.get_extension().is_empty():
			add_asset_folder(file)
		else:
			add_asset(file, "")


func toggle_asset_collection(asset: AssetResource, collection: AssetCollection, add: bool):
	if add:
		asset.tags.append(collection.id)
	else:
		asset.tags.erase(collection.id)
	AssetLibraryManager.get_asset_library().update_asset(asset)


func toggle_collection_filter(collection: AssetCollection, enabled: bool):
	if enabled:
		_active_collections.push_back(collection)
	else:
		_active_collections = _active_collections.filter(func(a): return a.id != collection.id)
	show_filter_info.emit(_active_collections.size())
	_filter_by_collections_and_query()


func _filter_by_collections_and_query():
	var all = AssetLibraryManager.get_asset_library().get_assets()
	var filtered: Array[AssetResource] = []

	for asset in all:
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
