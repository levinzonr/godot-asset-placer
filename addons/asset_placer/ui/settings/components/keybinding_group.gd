@tool
extends Container

var _keybinding_buttons: Array[APInputOptionButton]

func _ready():
	_resolve_children(self)
	for button in _keybinding_buttons:
		button.pressed.connect(func():
			get_viewport().set_input_as_handled()
			button.bind()
			cancel_others(button)
		)
		
		
func cancel_others(except: APInputOptionButton):
	for button in _keybinding_buttons:
		if button != except:
			button.cancel()
		
	
func _resolve_children(parent: Control):
	for child in parent.get_children():
		if child is APInputOptionButton:
			_keybinding_buttons.push_back(child)
			return
		elif child is Control:
			_resolve_children(child)
