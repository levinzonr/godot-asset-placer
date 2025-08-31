@tool
extends HBoxContainer
class_name SpinBoxVector3

signal value_changed(vector: Vector3)

@export var min: Vector3
@export var max: Vector3 
@export var label: String

@onready var spin_x := SpinBox.new()
@onready var spin_y := SpinBox.new()
@onready var spin_z := SpinBox.new()


@export var uniform: bool = false
@export var normalized: bool = false

func _ready():
	_add_spinbox("X", spin_x, min.x, max.y)
	_add_spinbox("Y", spin_y, min.y, max.y)
	_add_spinbox("Z", spin_z, min.z, max.z)
	
	spin_x.value_changed.connect(react_to_value_change)
	spin_z.value_changed.connect(react_to_value_change)
	spin_y.value_changed.connect(react_to_value_change)

func set_value_no_signal(vector: Vector3):
	spin_x.set_value_no_signal(vector.x)
	spin_y.set_value_no_signal(vector.y)
	spin_z.set_value_no_signal(vector.z)
		

func _add_spinbox(axis: String, spinbox: SpinBox, min: float, max: float) -> void:
	var label := Label.new()
	label.text = "%s:" % axis
	label.size = Vector2(10, 0)
	spinbox.prefix = "%s:" % axis
	spinbox.min_value = min
	spinbox.max_value = max
	spinbox.step = 0.1
	spinbox.editable = true
	add_child(spinbox)

func react_to_value_change(v: float):
	if uniform:
		set_value_no_signal(Vector3(v, v,v))
	
	if normalized:
		set_value_no_signal(get_vector().normalized())
	
	value_changed.emit(get_vector())
	

func get_vector() -> Vector3:
	return Vector3(spin_x.value, spin_y.value, spin_z.value)
