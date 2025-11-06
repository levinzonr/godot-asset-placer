@tool
extends Popup
class_name CollectionEditPopupMenu

signal on_save(collection: AssetCollection)
var collection_to_edit: AssetCollection
@onready var color_picker_button: ColorPickerButton = %ColorPickerButton
@onready var save_button: Button = %SaveButton
@onready var text_edit: TextEdit= %TextEdit

func _ready():
	if not collection_to_edit:
		return
	color_picker_button.color = collection_to_edit.backgroundColor
	text_edit.text = collection_to_edit.name
	text_edit.grab_focus()
	text_edit.text_changed.connect(func():
		save_button.disabled = text_edit.text.is_empty()
		collection_to_edit.name = text_edit.text
	)
	
	color_picker_button.color_changed.connect(func(color):
		collection_to_edit.backgroundColor = color
	)
	
	save_button.pressed.connect(func():
		on_save.emit(collection_to_edit)
		queue_free()
	)
	

static func show_popup(collection: AssetCollection, on_save: Callable):
	var dialog = load("res://addons/asset_placer/ui/asset_collections_window/edit/collection_edit_popup.tscn").instantiate()
	dialog.collection_to_edit = collection
	dialog.on_save.connect(on_save)
	EditorInterface.popup_dialog_centered(dialog)
	
	
