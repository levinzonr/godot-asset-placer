@tool
extends Button
class_name SystemIconButton

enum SystemIcon {
	Godot,
	Reload,
	Folder,
	FolderNew,
	Add,
	Remove,
	Edit,
	Play,
	Stop
}

@export var icon_type: SystemIcon = SystemIcon.Godot:
	set(value):
		icon_type = value
		_update_icon()

func _ready():
	if Engine.is_editor_hint():
		_update_icon()
		

func _update_icon():
	var icon_name := _get_icon_name_from_enum(icon_type)
	var editor_theme = EditorInterface.get_editor_theme()
	icon = editor_theme.get_icon(icon_name, "EditorIcons")
	tooltip_text = icon_name
	
func _get_icon_name_from_enum(value: int) -> String:
	match value:
		SystemIcon.Godot: return "Godot"
		SystemIcon.Reload: return "Reload"
		SystemIcon.Folder: return "Folder"
		SystemIcon.FolderNew: return "FolderCreate"
		SystemIcon.Add: return "Add"
		SystemIcon.Remove: return "Remove"
		SystemIcon.Edit: return "Edit"
		SystemIcon.Play: return "Play"
		SystemIcon.Stop: return "Stop"
	return "Godot"
