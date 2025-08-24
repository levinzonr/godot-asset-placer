@tool
extends Control
@onready var rotate_check_button: CheckBox = %RotateCheckButton
@onready var scale_check_button: CheckBox = %ScaleCheckButton
@onready var translate_check_button: CheckBox = %TranslateCheckButton
@onready var x_check_button: CheckButton = %XCheckButton
@onready var z_check_button: CheckButton = %ZCheckButton
@onready var y_check_button: CheckButton = %YCheckButton
func _ready():
	hide()
	var presenter = AssetPlacerPresenter._instance
	presenter.transform_mode_changed.connect(set_mode)
	presenter.preview_transform_axis_changed.connect(set_axis)
	presenter.asset_selected.connect(func(a): show())
	presenter.asset_deselected.connect(func(): hide())
	
	set_mode(presenter.transform_mode)
	set_axis(presenter.preview_transform_axis)


func set_mode(mode: AssetPlacerPresenter.TransformMode):
	rotate_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Rotate
	scale_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Scale
	translate_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Move


func set_axis(vector: Vector3):
	x_check_button.button_pressed = vector.x == 1
	y_check_button.button_pressed = vector.y == 1
	z_check_button.button_pressed = vector.z == 1
