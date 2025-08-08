@tool
extends Control


@onready var version_label: Label = %VersionLabel


func _ready():
	version_label.text = "Version %s" % get_plugin_version()

func get_plugin_version() -> String:
	var plugin_cfg_path = "res://addons/asset_placer/plugin.cfg";
	var file = FileAccess.open(plugin_cfg_path, FileAccess.READ)
	var config = ConfigFile.new()
	var err = config.load(plugin_cfg_path)
	var version = config.get_value("plugin", "version", "unknown")
	return version
