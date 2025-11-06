extends RefCounted
class_name PluginUpdater


static var instance: PluginUpdater


signal updater_up_to_date
signal updater_update_available(update: PluginUpdate)
signal update_ready(update: PluginUpdate)
signal show_update_loading(bool)

var _local_plugin_path: String
var _remote_plugin_path: String
var _client: PluginUpdaterHttpClient
var _latest_update: PluginUpdate

const TMP_ZIP_TEMPLATE = "user://asset-placer-{version}.zip"

func _init(local_config_path: String, remote_config_path: String):
	self._local_plugin_path = local_config_path
	self._remote_plugin_path = remote_config_path
	self._client = PluginUpdaterHttpClient.new()
	instance = self
	
	
func check_for_updates(channel: AssetPlacerSettings.UpdateChannel = AssetPlacerSettings.UpdateChannel.Stable):
	_latest_update = await _get_latest_update(channel)
	if !_latest_update:
		return
		
	var current_version = PluginConfiguration.new(_local_plugin_path).version
	if current_version.compare_to(_latest_update.version) < 0:
		if _is_update_downloaded():
			update_ready.emit(_latest_update)
		else:
			updater_update_available.emit(_latest_update)
	else:
		updater_up_to_date.emit()

		
	
func do_update():		
	show_update_loading.emit(true)
	var url_path = _latest_update.download_url
	_client.client_get(url_path)
	
	var zip: PackedByteArray = await _client.client_response
	var zip_path = _get_zip_path_for_version(_latest_update.version.to_string())
	var tmp_file = FileAccess.open(zip_path, FileAccess.WRITE)
	tmp_file.store_buffer(zip)
	tmp_file.close()
	
	show_update_loading.emit(false)
	update_ready.emit(_latest_update)

func apply_update():
	
	if FileAccess.open("res://docs/addon_folders.png", FileAccess.READ):
		push_error("Trying to update plugin from within a plugin")
		return
	
	show_update_loading.emit(true)
	
	var zip_path = _get_zip_path_for_version(_latest_update.version.to_string())
	var zip_reader: ZIPReader = ZIPReader.new()
	if zip_reader.open(zip_path) != OK:
		push_error("Failed to open downloaded ZIP file")
		show_update_loading.emit(false)
		return
		
	var files: PackedStringArray = zip_reader.get_files()
	
	# Move old plugin to trash
	OS.move_to_trash(ProjectSettings.globalize_path("res://addons/asset_placer"))
	
	var base_path: String
	for path in files:
		if path.ends_with("/addons/"):
			base_path = path
			break
	
	if base_path.is_empty():
		push_error("Could not find addons folder in ZIP")
		zip_reader.close()
		DirAccess.remove_absolute(zip_path)
		show_update_loading.emit(false)
		return

	for path in files:
		if not path.contains(base_path):
			continue
		
		var new_file_path: String = path.replace(base_path, "")
		if path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute("res://addons/%s" % new_file_path)
		else:
			var file: FileAccess = FileAccess.open("res://addons/%s" % new_file_path, FileAccess.WRITE)
			if file:
				file.store_buffer(zip_reader.read_file(path))
				file.close()
			else:
				push_error("Failed to write file: res://addons/%s" % new_file_path)

	zip_reader.close()
	DirAccess.remove_absolute(zip_path)
	show_update_loading.emit(false)
	EditorInterface.restart_editor(true)
	


func _is_update_downloaded() -> bool:
	if !_latest_update:
		return false
	var zip_path = _get_zip_path_for_version(_latest_update.version.to_string())
	var tmp_file = FileAccess.open(zip_path, FileAccess.READ)
	if not tmp_file:
		return false
	tmp_file.close()
	return true

func _get_latest_update(channel: AssetPlacerSettings.UpdateChannel = AssetPlacerSettings.UpdateChannel.Stable) -> PluginUpdate:
	# Fetch all releases
	_client.client_get("https://api.github.com/repos/levinzonr/godot-asset-placer/releases")
	var response: PackedByteArray = await _client.client_response
	if response.is_empty():
		return null
		
	var json_string = response.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return null
		
	var releases = json.data
	if not releases is Array:
		return null
	
	var latest_release = null
	var latest_version: Version = null
	
	for release in releases:
		var release_dict = release as Dictionary
		if not release_dict:
			continue
			
		var tag_name = release_dict.get("tag_name", "")
		if tag_name.is_empty():
			continue
		
		# Parse version to check channel compatibility
		var version = Version.new(tag_name)
		
		# Filter releases based on channel using Version class
		var matches_channel = false
		match channel:
			AssetPlacerSettings.UpdateChannel.Stable:
				matches_channel = version.identifier == null
			AssetPlacerSettings.UpdateChannel.Beta:
				matches_channel = version.identifier == null or version.identifier.track != Version.Track.Alpha
			AssetPlacerSettings.UpdateChannel.Alpha:
				# For alpha channel, include all releases (no filtering)
				matches_channel = true
		
		if not matches_channel:
			continue
		
		# Check if this is the latest version for this channel
		if latest_version == null or version.compare_to(latest_version) > 0:
			latest_version = version
			latest_release = release_dict
	
	if not latest_release:
		return null
	
	var tag_name = latest_release["tag_name"]
	var change_log = latest_release["body"]
	var download_url = latest_release["zipball_url"]
	return PluginUpdate.new(tag_name, change_log, download_url)
	
	
func _get_zip_path_for_version(version: String) -> String:
	return TMP_ZIP_TEMPLATE.format({"version": version})
