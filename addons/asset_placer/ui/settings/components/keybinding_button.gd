@tool
extends Button

signal key_binding_changed(option: APInputOption)

enum State {
	IDLE,
	BINDING_SELECT
}

var _current_key: APInputOption = APInputOption.none()
@export var allow_modifiers: bool = true
@export var allow_mouse_buttons: bool = false

var current_key: APInputOption:
	get:
		return _current_key
	set(value):
		_current_key = value
		_update_display()
		key_binding_changed.emit(_current_key)

var _state: State = State.IDLE

func _ready() -> void:
	_update_display()
	pressed.connect(_start_binding)

func _input(event: InputEvent) -> void:
	if _state == State.BINDING_SELECT:
		if event is InputEventKey and event.pressed:
			get_viewport().set_input_as_handled()
			if event.keycode == Key.KEY_ESCAPE:
				_stop_binding()
				return
			_current_key = APInputOption.key_press(event.keycode)
			_stop_binding()
		if allow_mouse_buttons and event is InputEventMouseButton:
			get_viewport().set_input_as_handled()
			current_key = APInputOption.mouse_press(event.button_index)
			_stop_binding()


func set_key_binding(key: APInputOption) -> void:
	_current_key = key
	_update_display()
	
func _start_binding() -> void:
	_state = State.BINDING_SELECT
	if allow_mouse_buttons:
		text = "Press Any key or Mouse, ESC To Cancel"
	else:
		text = "Press Any Key, ESC to Cancel"
	modulate = Color(1.0, 1.0, 0.5)  # Slightly yellow tint to indicate listening state

func _stop_binding() -> void:
	_state = State.IDLE
	_update_display()
	modulate = Color.WHITE

func _update_display() -> void:
	text = _current_key.get_display_name()
