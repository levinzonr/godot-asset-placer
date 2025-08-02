@tool
extends Control

var presenter: AssetPlacerPresenter
@onready var grid_snapping_checkbox = %GridSnappingCheckbox
@onready var grid_snap_value_spin_box: SpinBox = %GridSnapValueSpinBox
@onready var x_rotation_checkbox: CheckBox = %XRotationCheckbox
@onready var z_rotation_checkbox: CheckBox = %ZRotationCheckbox
@onready var y_rotation_checkbox: CheckBox = %YRotationCheckbox


func _ready():
	presenter = AssetPlacerPresenter._instance
	presenter.options_changed.connect(set_options)
	presenter.ready()
	
	grid_snapping_checkbox.toggled.connect(presenter.set_grid_snapping_enabled)
	
	x_rotation_checkbox.toggled.connect(func(x):
		presenter.set_transform_rotation(x, y_rotation_checkbox.button_pressed, z_rotation_checkbox.button_pressed)
	)
	
	y_rotation_checkbox.toggled.connect(func(y):
		presenter.set_transform_rotation(x_rotation_checkbox.button_pressed, y, z_rotation_checkbox.button_pressed)
	)
	
	z_rotation_checkbox.toggled.connect(func(z):
		presenter.set_transform_rotation(x_rotation_checkbox.button_pressed, y_rotation_checkbox.button_pressed,z)

	)
	


func set_options(options: AssetPlacerOptions):
	grid_snapping_checkbox.set_pressed_no_signal(options.snapping_enabled)
	grid_snap_value_spin_box.editable = options.snapping_enabled
	grid_snap_value_spin_box.set_value_no_signal(options.snapping_grid_step)
	x_rotation_checkbox.set_pressed_no_signal(options.transform_rotate_x)	
	y_rotation_checkbox.set_pressed_no_signal(options.transform_rotate_y)	
	z_rotation_checkbox.set_pressed_no_signal(options.transform_rotate_z)	
	
	
	
