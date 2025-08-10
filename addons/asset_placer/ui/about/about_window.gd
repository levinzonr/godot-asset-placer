@tool
extends Control


@onready var version_label: Label = %VersionLabel

@onready var feature_request_button: Button = %FeatureRequestButton
@onready var issue_button: Button = %IssueButton
@onready var update_button: Button = %UpdateButton
@onready var update_version_label: Label = %UpdateVersionLabel
@onready var changelog_link_button: LinkButton = %ChangelogLinkButton
@onready var update_and_restart_btn: Button = %UpdateAndRestartBtn
@onready var progress_bar: ProgressBar = $UpdatePopup/MarginContainer/Vbox/ProgressBar
@onready var update_popup: Popup = $UpdatePopup

const FEATURE_TEMPLATE = "https://github.com/levinzonr/godot-asset-placer/issues/new?template=feature_request.md&labels=enhancement&title=%5BFeature%5D%20"
const ISSUE_TEMPLATE = "https://github.com/levinzonr/godot-asset-placer/issues/new?template=bug_report.md&labels=bug&title=%5BBUG%5D%20"


var updater: PluginUpdater = PluginUpdater.instance

func _ready():
	
	updater.show_update_loading.connect(func(show):
		if show:
			update_and_restart_btn.disabled = true
			progress_bar.show()
		else:
			update_and_restart_btn.disabled = false
			progress_bar.hide()
	)
	updater.updater_update_available.connect(func(update: PluginUpdate):
		update_button.text = "Version %s Availalbe" % update.version
		update_button.show()
		update_version_label.text = update.version._to_string()
		changelog_link_button.uri = "https://github.com/levinzonr/godot-asset-placer/blob/main/CHANGELOG.md#" +  update.version.changelog_version()
	)
	updater.updater_up_to_date.connect(update_button.hide)
	
	
	updater.check_for_updates()
	update_button.pressed.connect(update_popup.popup)
	update_and_restart_btn.pressed.connect(updater.do_update)
	version_label.text = "Version %s" % get_plugin_version()
	issue_button.pressed.connect(func():
		OS.shell_open(ISSUE_TEMPLATE)
	)
	feature_request_button.pressed.connect(func():
		OS.shell_open(FEATURE_TEMPLATE)
	)

func get_plugin_version() -> String:
	return PluginConfiguration.new("res://addons/asset_placer/plugin.cfg").version.to_string()
