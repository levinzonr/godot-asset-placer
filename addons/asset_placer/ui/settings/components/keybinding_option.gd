@tool
extends Control


signal keybind_changed(option: APInputOption)


@onready var key_bind_button: Button = %KeyBindButton
@onready var key_bind_label: Label = %KeyBindLabel
@export var allow_mouse_buttons: bool:
	set(value):
		allow_mouse_buttons = value
		if key_bind_button:
			key_bind_button.allow_mouse_buttons = value

@export var label: String = "Label":
	set(value):
		label = value
		if key_bind_label:
			key_bind_label.text = value
		


func _ready():
	key_bind_button.key_binding_changed.connect(keybind_changed.emit)
	key_bind_label.text = label
	key_bind_button.allow_mouse_buttons = allow_mouse_buttons

func set_keybind(key: APInputOption):
	key_bind_button.set_keybind_no_signal(key)
