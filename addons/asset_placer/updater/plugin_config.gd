class_name PluginConfiguration
extends RefCounted

var version: Version


func _init(file_path: String):
	var config = ConfigFile.new()
	config.load(file_path)
	self.version = Version.new(config.get_value("plugin", "version", "unknown"))
