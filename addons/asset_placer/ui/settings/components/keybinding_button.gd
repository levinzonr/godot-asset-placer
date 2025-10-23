@tool
class_name APInputOptionButton
extends Button

signal key_binding_changed(option: APInputOption)
signal key_binding_active

@export var allow_modifiers: bool = true
@export var allow_mouse_buttons: bool = false

enum State {
	Bind, Idle
}

var _current_key: APInputOption = APInputOption.none()
var _pending_key: APInputOption = null
var _pending_modifier: KeyModifierMask = 0
var _pressed: int = 0

var _modifier_keys: Dictionary[Key, KeyModifierMask] = {
	Key.KEY_META: KeyModifierMask.KEY_MASK_META,
	Key.KEY_SHIFT: KeyModifierMask.KEY_MASK_SHIFT,
	Key.KEY_ALT: KeyModifierMask.KEY_MASK_ALT,
	Key.KEY_CTRL: KeyModifierMask.KEY_MASK_CTRL
}

var _state: = State.Idle:
	set(state):
		_state = state
		match _state:
			State.Idle: on_idle()
			State.Bind: on_bind()
	

func on_idle():
	text = _current_key.get_display_name()
	modulate = Color.WHITE
	
	if _current_key.equals(APInputOption.none()):
		modulate = Color.RED	

func on_bind():
	text = _get_helper_text()
	modulate = Color(0.945, 1.0, 0.353, 1.0)
	key_binding_active.emit()

func bind():
	_state = State.Bind	
	_pending_key = null
	_pending_modifier = 0
	_pressed = 0
	
func cancel():
	_state = State.Idle	
	_pending_key = null
	_pending_modifier = 0
	_pressed = 0
	
func _process(delta):
	match _state:
		State.Idle:
			pass
		State.Bind:
			text = _get_pending_text()
			if text.is_empty():
				text = _get_helper_text()
				
func set_keybind_no_signal(key: APInputOption) -> void:
	_current_key = key
	text = key.get_display_name()
	if _current_key.equals(APInputOption.none()):
		modulate = Color.RED
	else:
		modulate = Color.WHITE
	

func _input(event: InputEvent):
	match _state:
		State.Bind: _process_bind_input(event)
		State.Idle: pass
			

func _process_bind_input(event: InputEvent):
	
	if Input.is_key_pressed(Key.KEY_ESCAPE):
		cancel()
		return
	
	get_viewport().set_input_as_handled()
	if event is InputEventKey:
		if event.is_pressed():
			_process_input_key_event_pressed(event)
		if event.is_released():
			_process_input_key_event_released(event)
	if event is InputEventMouseButton:
		if event.is_pressed():
			_pending_key = APInputOption.mouse_press(event.button_index)
			_pressed += 1
		else:
			_pressed -= 1
			if _pressed == 0:
				_stop_binding()
			
	
	
func _process_input_key_event_pressed(event: InputEventKey):
	var key_code = event.keycode
	if key_code in _modifier_keys.keys() and allow_modifiers:
		_pending_modifier = _pending_modifier | _modifier_keys[key_code]
	else:
		_pending_key = APInputOption.key_press(key_code)
		
	_pressed += 1
	

func _process_input_key_event_released(event: InputEventKey):
	_pressed -= 1
	if _pressed == 0:
		_stop_binding()


func _stop_binding():
	if allow_modifiers and _pending_modifier != Key.KEY_NONE:
		var final_keybind = _pending_key
		_pending_key.modifiers = _pending_modifier
		_current_key = final_keybind
		key_binding_changed.emit(_current_key)
		_state = State.Idle
	else:
		_current_key = _pending_key
		key_binding_changed.emit(_current_key)
		_state = State.Idle

	_pending_key = null
	_pending_modifier = 0
		

func _get_helper_text() -> String:
	return "Press Any Key, ESC to Cancel"
	
func _get_pending_text() -> String:
	var final_text := ""
	if _pending_key != null:
		final_text += _pending_key.get_display_name()
		
	if _pending_modifier != 0:
		final_text = OS.get_keycode_string(Key.KEY_NONE | _pending_modifier) + final_text

	return final_text
