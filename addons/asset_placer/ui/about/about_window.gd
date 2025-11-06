@tool
extends Control


@onready var version_label: Label = %VersionLabel

@onready var feature_request_button: Button = %FeatureRequestButton
@onready var issue_button: Button = %IssueButton
@onready var update_button: Button = %UpdateButton
@onready var apply_update_button: Button = %ApplyUpdateAndRestartBtn
@onready var update_version_label: Label = %UpdateVersionLabel
@onready var changelog_link_button: LinkButton = %ChangelogLinkButton
@onready var download_update_button: Button = %DownloadUpdateBtn
@onready var progress_bar: ProgressBar = $UpdatePopup/MarginContainer/Vbox/ProgressBar
@onready var update_popup: Popup = $UpdatePopup

@onready var settings_repository := AssetPlacerSettingsRepository.instance

const FEATURE_TEMPLATE = "https://github.com/levinzonr/godot-asset-placer/issues/new?template=feature_request.md&labels=enhancement&title=%5BFeature%5D%20"
const ISSUE_TEMPLATE = "https://github.com/levinzonr/godot-asset-placer/issues/new?template=bug_report.md&labels=bug&title=%5BBUG%5D%20"


var updater: PluginUpdater = PluginUpdater.instance

func _ready():
	var settings = settings_repository.get_settings()
	settings_repository.settings_changed.connect(func(s): 
		updater.check_for_updates(s.update_channel)
	)
	updater.show_update_loading.connect(_show_update_loading)
	updater.updater_update_available.connect(_show_update_available_for_download)
	updater.update_ready.connect(_show_update_ready_to_apply)
	updater.updater_up_to_date.connect(update_button.hide)
	updater.check_for_updates(settings.update_channel)
	update_button.pressed.connect(update_popup.popup)
	download_update_button.pressed.connect(updater.do_update)
	apply_update_button.pressed.connect(updater.apply_update)
	version_label.text = "Version %s" % get_plugin_version()
	issue_button.pressed.connect(func():
		OS.shell_open(ISSUE_TEMPLATE)
	)
	feature_request_button.pressed.connect(func():
		OS.shell_open(FEATURE_TEMPLATE)
	)
	
func _show_update_available_for_download(update: PluginUpdate):
		update_button.text = "Version %s Availalbe" % update.version
		update_button.show()
		apply_update_button.hide()
		update_version_label.text = update.version._to_string()
		changelog_link_button.uri = "https://github.com/levinzonr/godot-asset-placer/releases/tag/" +  update.version.to_string()


func _show_update_loading(loading: bool):
	if loading:
		download_update_button.disabled = true
		progress_bar.show()
	else:
		download_update_button.disabled = false
		progress_bar.hide()

func _show_update_ready_to_apply(update: PluginUpdate):
		update_button.text = "Version %s Availalbe" % update.version
		update_button.show()
		download_update_button.hide()
		apply_update_button.show()
		update_version_label.text = update.version._to_string()
		changelog_link_button.uri = "https://github.com/levinzonr/godot-asset-placer/blob/main/CHANGELOG.md#" +  update.version.changelog_version()

func get_plugin_version() -> String:
	return PluginConfiguration.new("res://addons/asset_placer/plugin.cfg").version.to_string()
