@tool
class_name AssetLibrary
extends RefCounted

var _assets: Array[AssetResource] = []
var _folders: Array[AssetFolder] = []
var _collections: Array[AssetCollection] = []


func _init(
	assets: Array[AssetResource], folders: Array[AssetFolder], collections: Array[AssetCollection]
):
	_assets = assets
	_folders = folders
	_collections = collections


func get_assets() -> Array[AssetResource]:
	return _assets


func get_folders() -> Array[AssetFolder]:
	return _folders


func get_collections() -> Array[AssetCollection]:
	return _collections


func index_of_asset(asset: AssetResource):
	var idx: int = -1
	for a in len(_assets):
		if _assets[a].id == asset.id:
			idx = a
			break
	return idx


func get_highest_id() -> int:
	var highest := 0
	for collection in _collections:
		if collection.id > highest:
			highest = collection.id
	return highest


## Signals


func _emit_queued_signals():
	if _is_assets_changed_queued:
		assets_changed.emit()
	if _is_folders_changed_queued:
		folders_changed.emit()
	if _is_collections_changed_queued:
		collections_changed.emit()

	_is_assets_changed_queued = false
	_is_folders_changed_queued = false
	_is_collections_changed_queued = false


func _queue_emit_assets_changed():
	if not _is_signal_queued:
		_emit_queued_signals.call_deferred()
	_is_assets_changed_queued = true


func _queue_emit_folders_changed():
	if not _is_signal_queued:
		_emit_queued_signals.call_deferred()
	_is_folders_changed_queued = true


func _queue_emit_collections_changed():
	if not _is_signal_queued:
		_emit_queued_signals.call_deferred()
	_is_collections_changed_queued = true


## Only used by AssetLibraryManager
func _emit_all_changed():
	assets_changed.emit()
	folders_changed.emit()
	collections_changed.emit()
