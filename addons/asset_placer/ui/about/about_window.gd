@tool
extends Control


@onready var version_label: Label = %VersionLabel

@onready var feature_request_button: Button = %FeatureRequestButton
@onready var issue_button: Button = %IssueButton


const FEATURE_TEMPLATE = "https://github.com/levinzonr/godot-asset-placer/issues/new?template=feature_request.md&labels=enhancement&title=%5BFeature%5D%20"
const ISSUE_TEMPLATE = "https://github.com/levinzonr/godot-asset-placer/issues/new?template=bug_report.md&labels=bug&title=%5BBUG%5D%20"

func _ready():
	version_label.text = "Version %s" % get_plugin_version()
	issue_button.pressed.connect(func():
		OS.shell_open(ISSUE_TEMPLATE)
	)
	feature_request_button.pressed.connect(func():
		OS.shell_open(FEATURE_TEMPLATE)
	)

func get_plugin_version() -> String:
	var plugin_cfg_path = "res://addons/asset_placer/plugin.cfg";
	var file = FileAccess.open(plugin_cfg_path, FileAccess.READ)
	var config = ConfigFile.new()
	var err = config.load(plugin_cfg_path)
	var version = config.get_value("plugin", "version", "unknown")
	return version
