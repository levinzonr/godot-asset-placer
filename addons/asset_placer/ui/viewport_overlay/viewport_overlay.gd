@tool
extends Control
@onready var rotate_check_button: CheckBox = %RotateCheckButton
@onready var scale_check_button: CheckBox = %ScaleCheckButton
@onready var translate_check_button: CheckBox = %TranslateCheckButton
@onready var x_check_button: CheckButton = %XCheckButton
@onready var z_check_button: CheckButton = %ZCheckButton
@onready var y_check_button: CheckButton = %YCheckButton
@onready var placement_mode_label: Label = %PlacementModeLabel
@onready var error_label: Label = %ErrorLabel
@onready var error_container = %ErrorContainer
@onready var error_timer: Timer = %ErrorTimer
@onready var snapping_switch: CheckButton = %SnappingSwitch


func _ready():
	hide()
	error_container.hide()
	var presenter = AssetPlacerPresenter._instance
	presenter.transform_mode_changed.connect(set_mode)
	presenter.preview_transform_axis_changed.connect(set_axis)
	presenter.asset_selected.connect(func(a): show())
	presenter.asset_deselected.connect(func(): hide())
	presenter.placement_mode_changed.connect(set_placement_mode)
	presenter.options_changed.connect(show_options)
	presenter.show_error.connect(show_error)
	error_timer.timeout.connect(hide_error)
	set_mode(presenter.transform_mode)
	set_axis(presenter.preview_transform_axis)


func set_mode(mode: AssetPlacerPresenter.TransformMode):
	rotate_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Rotate
	scale_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Scale
	translate_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Move

func set_placement_mode(mode: PlacementMode):
	if mode is PlacementMode.PlanePlacement:
		placement_mode_label.text = "Plane Placement"
	if mode is PlacementMode.SurfacePlacement:
		placement_mode_label.text = "Surface Placement"
	if mode is PlacementMode.Terrain3DPlacement:
		placement_mode_label.text = "Terrain3D Placement"
		
		 
func show_error(message: String):
	error_container.show()
	error_label.text = message
	error_timer.start()

func hide_error():
	error_container.hide()


func show_options(options: AssetPlacerOptions):
	snapping_switch.button_pressed = options.snapping_enabled	
		
func set_axis(vector: Vector3):
	x_check_button.button_pressed = vector.x == 1
	y_check_button.button_pressed = vector.y == 1
	z_check_button.button_pressed = vector.z == 1
