extends RefCounted
class_name APInputOption


func is_pressed(event: InputEvent) -> bool:
	return false

func get_display_name() -> String:
	return ""
	
func serialize() -> String:
	return ""	
	
class KeyPress extends APInputOption:
	var key: Key
	func _init(keys: Key):
		self.key = keys
	
	func get_display_name() -> String:
		return OS.get_keycode_string(key)
	
	func is_pressed(event: InputEvent) -> bool:
		if event is InputEventKey and event.is_pressed():
			return event.keycode == key
		else:
			return false
			
	func serialize() -> String:
		return "key_%s" % str(key)

class MousePress extends  APInputOption:
	var mouse_index: MouseButton
	
	func _init(mouse_index: MouseButton):
		self.mouse_index = mouse_index
	
	func serialize() -> String:
		return "mouse_%s" % str(mouse_index)	
		
	func is_pressed(event: InputEvent) -> bool:
		if event is InputEventMouseButton:
			return event.is_pressed() and event.button_index == mouse_index
		else:
			return false	
		
	func get_display_name() -> String:
		match mouse_index:
			MouseButton.MOUSE_BUTTON_LEFT:
				return "LMB"
			MouseButton.MOUSE_BUTTON_RIGHT:
				return "RMB"
			MouseButton.MOUSE_BUTTON_MIDDLE:
				return "MMB"
			MouseButton.MOUSE_BUTTON_XBUTTON1:
				return "Extra 1"
			MouseButton.MOUSE_BUTTON_XBUTTON2:
				return "Extra 2"
			_:
				return "Not supported"


static func desirialize(raw: String) -> APInputOption:
	if raw.begins_with("mouse_"):
		var mouse_index = raw.split("_")[1]
		return mouse_press(mouse_index.to_int())
	else:
		var button_index = raw.split("_")[1]
		return key_press(button_index.to_int())

static func none() -> APInputOption:
	return APInputOption.KeyPress.new(Key.KEY_NONE)
	
	
static func key_press(key: Key) -> APInputOption:
	return APInputOption.KeyPress.new(key)
	
static func mouse_press(mouse_button: MouseButton) -> APInputOption:
	return APInputOption.MousePress.new(mouse_button)
