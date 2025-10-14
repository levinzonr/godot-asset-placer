@tool
extends Button

signal key_binding_changed(new_key: Key)

enum State {
	IDLE,
	BINDING_SELECT
}

@export var current_key: Key = KEY_NONE
@export var helper_text: String = "Press any key..."
@export var allow_modifiers: bool = true

var _state: State = State.IDLE

func _ready() -> void:
	_update_display()
	pressed.connect(_start_binding)

func _input(event: InputEvent) -> void:
	if _state == State.BINDING_SELECT:
		if event is InputEventKey and event.pressed:
			get_viewport().set_input_as_handled()
			_set_new_key(event.keycode)


func set_key_binding(key: Key) -> void:
	current_key = key
	_update_display()
	
	
func _start_binding() -> void:
	_state = State.BINDING_SELECT
	text = helper_text
	modulate = Color(1.0, 1.0, 0.5)  # Slightly yellow tint to indicate listening state

func _stop_binding() -> void:
	_state = State.IDLE
	_update_display()
	modulate = Color.WHITE

func _set_new_key(key: Key) -> void:
	current_key = key
	_stop_binding()
	key_binding_changed.emit(current_key)

func _update_display() -> void:
	if current_key == KEY_NONE:
		text = "None"
	else:
		text = OS.get_keycode_string(current_key)
