@tool
class_name AssetPlacerFolderRule
extends RefCounted


## Returns the type ID for this rule (used by factory)
func get_type_id() -> String:
	return "base"


## Returns the display name of this rule for the UI
func get_rule_name() -> String:
	return "Base Rule"


## Returns a description of what this rule does
func get_rule_description() -> String:
	return ""


## Serializes this rule to a dictionary
func to_dict() -> Dictionary:
	return {
		"type": get_type_id(),
	}


## Deserializes properties from a dictionary
func from_dict(_data: Dictionary):
	pass


## Creates the complete UI row for this rule.
## on_changed(rule) is called when rule config changes.
## on_remove() is called when remove is clicked.
func create_ui(on_changed: Callable, on_remove: Callable) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size.y = 36
	row.add_theme_constant_override("separation", 12)

	var name_label = Label.new()
	name_label.text = get_rule_name()
	row.add_child(name_label)

	var config_container = HBoxContainer.new()
	config_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(config_container)

	_create_config_ui(config_container, on_changed)

	var remove_button = Button.new()
	remove_button.icon = EditorInterface.get_base_control().get_theme_icon("Remove", "EditorIcons")
	remove_button.pressed.connect(on_remove)
	row.add_child(remove_button)

	return row


## Override in subclasses to add rule-specific controls.
func _create_config_ui(_container: Control, _on_changed: Callable):
	pass


## Called to filter files. Return false to skip/remove.
func do_filter(_file_name: String) -> bool:
	return true


## Called after an asset is added. Can modify the asset and return it.
func do_after_asset_added(asset: AssetResource) -> AssetResource:
	return asset
