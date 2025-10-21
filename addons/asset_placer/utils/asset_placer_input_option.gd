extends RefCounted
class_name APInputOption

var modifiers: KeyModifierMask

func is_pressed(event: InputEvent) -> bool:
	return false

func get_display_name() -> String:
	return ""
	
func serialize() -> String:
	return ""	
	
class KeyPress extends APInputOption:
	var key: Key
	
	func _init(keys: Key, modifiers: KeyModifierMask = 0):
		self.key = keys
		self.modifiers = modifiers
	
	func get_display_name() -> String:
			return OS.get_keycode_string(key | modifiers)
	
	func is_pressed(event: InputEvent) -> bool:
		if event is InputEventKey and event.is_pressed():
			var event_mask = event.get_modifiers_mask()
			var with_mask = key | modifiers
			var event_combined = event.keycode | event_mask
			return event_combined == with_mask
		else:
			return false
			
	func serialize() -> String:
		return "key_%s_%s" % [str(key), str(modifiers)]

class MousePress extends  APInputOption:
	var mouse_index: MouseButton
	
	func _init(mouse_index: MouseButton, modifiers: KeyModifierMask = 0):
		self.mouse_index = mouse_index
		self.modifiers = modifiers
	
	func serialize() -> String:
		return "mouse_%s_%s" % [str(mouse_index), str(modifiers)]	
		
	func is_pressed(event: InputEvent) -> bool:
		if event is InputEventMouseButton and event.is_pressed():
			var event_modifiers: KeyModifierMask = 0
			if event.shift_pressed:
				event_modifiers |= KeyModifierMask.KEY_MASK_SHIFT
			if event.ctrl_pressed:
				event_modifiers |= KeyModifierMask.KEY_MASK_CTRL
			if event.alt_pressed:
				event_modifiers |= KeyModifierMask.KEY_MASK_ALT
			if event.meta_pressed:
				event_modifiers |= KeyModifierMask.KEY_MASK_META
			
			return event.button_index == mouse_index and event_modifiers == modifiers
		else:
			return false	
		
	func get_display_name() -> String:
		var button_name: String
		match mouse_index:
			MouseButton.MOUSE_BUTTON_LEFT:
				button_name = "LMB"
			MouseButton.MOUSE_BUTTON_RIGHT:
				button_name = "RMB"
			MouseButton.MOUSE_BUTTON_MIDDLE:
				button_name = "MMB"
			MouseButton.MOUSE_BUTTON_XBUTTON1:
				button_name = "Extra 1"
			MouseButton.MOUSE_BUTTON_XBUTTON2:
				button_name = "Extra 2"
			_:
				button_name = "Not supported"
		
		if modifiers == 0:
			return button_name
		else:
			return OS.get_keycode_string(Key.KEY_NONE | modifiers)  + button_name


static func desirialize(raw: String) -> APInputOption:
	if raw.begins_with("mouse_"):
		var parts = raw.split("_")
		var mouse_index = parts[1].to_int()
		var modifiers = parts[2].to_int() if parts.size() > 2 else 0
		return mouse_press(mouse_index, modifiers)
	else:
		var parts = raw.split("_")
		var key = parts[1].to_int()
		var modifiers = parts[2].to_int() if parts.size() > 2 else 0
		return key_press(key, modifiers)

static func none() -> APInputOption:
	return APInputOption.KeyPress.new(Key.KEY_NONE)
	
	
static func key_press(key: Key, modifiers: KeyModifierMask = 0) -> APInputOption:
	return APInputOption.KeyPress.new(key, modifiers)
	
static func mouse_press(mouse_button: MouseButton, modifiers: KeyModifierMask = 0) -> APInputOption:
	return APInputOption.MousePress.new(mouse_button, modifiers)
