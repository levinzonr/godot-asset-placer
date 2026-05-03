@tool
class_name ThumbnailRegenerationDialog
extends AcceptDialog

var _cancel_button: Button
var _coordinator: ThumbnailGenerationCoordinator
var _total := 0
var _done := 0
var _failed := 0
var _skipped := 0
var _success := 0

@onready var status_label: Label = %StatusLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var details_label: Label = %DetailsLabel


func _ready():
	_cancel_button = add_button("Cancel", true, "cancel")
	custom_action.connect(_on_custom_action)
	canceled.connect(_on_dialog_canceled)
	get_ok_button().text = "Close"
	get_ok_button().disabled = true
	_bind_coordinator()


func open_and_track():
	_bind_coordinator()
	if is_instance_valid(_coordinator) and not _coordinator.is_running():
		status_label.text = "Preparing thumbnail regeneration..."
		details_label.text = "Done 0/0"
		progress_bar.max_value = 1
		progress_bar.value = 0
		_cancel_button.disabled = true
	else:
		_cancel_button.disabled = false


func _bind_coordinator():
	_coordinator = ThumbnailGenerationCoordinator.instance
	if not is_instance_valid(_coordinator):
		status_label.text = "Thumbnail coordinator is unavailable."
		details_label.text = "Close and reopen the plugin."
		_cancel_button.disabled = true
		get_ok_button().disabled = false
		return

	if not _coordinator.started.is_connected(_on_started):
		_coordinator.started.connect(_on_started)
	if not _coordinator.progress.is_connected(_on_progress):
		_coordinator.progress.connect(_on_progress)
	if not _coordinator.failed_item.is_connected(_on_failed_item):
		_coordinator.failed_item.connect(_on_failed_item)
	if not _coordinator.finished.is_connected(_on_finished):
		_coordinator.finished.connect(_on_finished)
	if not _coordinator.canceled.is_connected(_on_canceled):
		_coordinator.canceled.connect(_on_canceled)


func _on_custom_action(action: String):
	if action == "cancel" and is_instance_valid(_coordinator):
		_coordinator.request_cancel()
		_cancel_button.disabled = true
		status_label.text = "Cancel requested, stopping..."


func _on_dialog_canceled():
	if is_instance_valid(_coordinator) and _coordinator.is_running():
		_coordinator.request_cancel()


func _on_started(total: int):
	_total = total
	_done = 0
	_failed = 0
	_skipped = 0
	_success = 0
	_cancel_button.disabled = false
	get_ok_button().disabled = true
	progress_bar.max_value = max(total, 1)
	progress_bar.value = 0
	status_label.text = "Generating custom thumbnails..."
	details_label.text = "Done 0/%d" % total


func _on_progress(done: int, total: int, current_path: String):
	_done = done
	progress_bar.max_value = max(total, 1)
	progress_bar.value = done
	details_label.text = "Done %d/%d | %s" % [done, total, current_path.get_file()]


func _on_failed_item(_path: String, _error: String):
	_failed += 1


func _on_finished(success: int, failed: int, skipped: int):
	_success = success
	_failed = failed
	_skipped = skipped
	_cancel_button.disabled = true
	get_ok_button().disabled = false
	status_label.text = "Thumbnail regeneration complete."
	details_label.text = "Created %d | Failed %d | Skipped %d" % [_success, _failed, _skipped]


func _on_canceled(success: int, failed: int, skipped: int):
	_success = success
	_failed = failed
	_skipped = skipped
	_cancel_button.disabled = true
	get_ok_button().disabled = false
	status_label.text = "Thumbnail regeneration canceled."
	details_label.text = "Created %d | Failed %d | Skipped %d" % [_success, _failed, _skipped]
