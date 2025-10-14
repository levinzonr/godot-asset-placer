@tool
extends Control


signal keybind_changed(key: Key)


@onready var key_bind_button: Button = %KeyBindButton
@onready var key_bind_label: Label = %KeyBindLabel

@export var label: String = "Label":
	set(value):
		label = value
		if key_bind_label:
			key_bind_label.text = value
		


func _ready():
	key_bind_button.key_binding_changed.connect(keybind_changed.emit)
	key_bind_label.text = label
	

func set_keybind(key: Key):
	key_bind_button.set_key_binding(key)
