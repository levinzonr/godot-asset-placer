extends RefCounted
class_name PluginUpdater


static var instance: PluginUpdater


signal updater_up_to_date
signal updater_update_available(update: PluginUpdate)
signal show_update_loading(bool)

var _local_plugin_path: String
var _remote_plugin_path: String
var _client: PluginUpdaterHttpClient
var _latest_update: PluginUpdate

const TMP_ZIP = "user://addon.zip"

func _init(local_config_path: String, remote_config_path: String):
	self._local_plugin_path = local_config_path
	self._remote_plugin_path = remote_config_path
	self._client = PluginUpdaterHttpClient.new()
	instance = self
	
	
func check_for_updates():
	_latest_update = await _get_latest_update()
	if !_latest_update:
		return
		
	var current_version = PluginConfiguration.new(_local_plugin_path).version
	if current_version.compare_to(_latest_update.version) < 0:
		updater_update_available.emit(_latest_update)
	else:
		updater_up_to_date.emit()

func do_update():
	
	if FileAccess.open("res://docs/addon_folders.png", FileAccess.READ):
		push_error("Trying to update plugin from within a plugin")
		return
		
	
	show_update_loading.emit(true)
	var url_path = _latest_update.download_url;
	_client.client_get(url_path)
	
	var zip: PackedByteArray = await _client.client_response
	var tmp_file = FileAccess.open(TMP_ZIP, FileAccess.WRITE)
	tmp_file.store_buffer(zip)
	var zip_reader: ZIPReader = ZIPReader.new()
	zip_reader.open(TMP_ZIP)
	var files: PackedStringArray = zip_reader.get_files()
	
	OS.move_to_trash(ProjectSettings.globalize_path("res://addons/asset_placer"))

	
	var base_path: String

	for path in files:
		if path.ends_with("/addons/"):
			base_path = path
			break
	
	

	for path in files:
		if not path.contains(base_path):
			continue
		
		var new_file_path: String = path.replace(base_path, "")
		if path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute("res://addons/%s" % new_file_path)
		else:
			var file: FileAccess = FileAccess.open("res://addons/%s" % new_file_path, FileAccess.WRITE)
			file.store_buffer(zip_reader.read_file(path))

	zip_reader.close()
	DirAccess.remove_absolute(TMP_ZIP)
	_do_post_update.call_deferred()
	EditorInterface.set_plugin_enabled("asset_placer", false)
	show_update_loading.emit(false)
	
func _do_post_update():
	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.set_plugin_enabled("asset_placer", true)

func _get_latest_update() -> PluginUpdate:
	_client.client_get("https://api.github.com/repos/levinzonr/godot-asset-placer/releases/latest")
	var response: PackedByteArray = await  _client.client_response
	if response.is_empty():
		return null
		
	var dict = JSON.parse_string(response.get_string_from_utf8())
	var tag_name = dict["tag_name"]
	var change_log = dict["body"]
	var download_url = dict["zipball_url"]
	return PluginUpdate.new(tag_name, change_log, download_url)
