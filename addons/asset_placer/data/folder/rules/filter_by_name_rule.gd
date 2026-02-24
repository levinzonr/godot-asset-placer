@tool
class_name FilterByNameRule
extends AssetPlacerFolderRule

var pattern: String = ""


func get_type_id() -> String:
	return "filter_by_name"


func get_rule_name() -> String:
	return "Filter by Name"


func get_rule_description() -> String:
	if pattern.is_empty():
		return "No pattern set"
	return "Include: *" + pattern + "*"


func to_dict() -> Dictionary:
	var data = super.to_dict()
	data["pattern"] = pattern
	return data


func from_dict(data: Dictionary):
	super.from_dict(data)
	if data.has("pattern"):
		pattern = data["pattern"]


func _create_config_ui(container: Control, on_changed: Callable):
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Enter text to match..."
	line_edit.text = pattern
	line_edit.custom_minimum_size.x = 200
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	line_edit.text_changed.connect(
		func(new_text):
			pattern = new_text
			on_changed.call(self)
	)

	container.add_child(line_edit)


func do_filter(file_name: String) -> bool:
	if pattern.is_empty():
		return true
	return file_name.containsn(pattern)
