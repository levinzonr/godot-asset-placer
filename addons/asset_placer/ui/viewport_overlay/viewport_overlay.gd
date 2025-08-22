@tool
extends Control

@onready var mode_label = $Label2
@onready var label_3 = $Label3
func _ready():
	var presenter = AssetPlacerPresenter._instance
	presenter.mode_changed.connect(set_mode)
	presenter.preview_transform_axis_changed.connect(set_axis)
	set_mode(presenter._mode)
	set_axis(presenter.preview_transform_axis)


func set_mode(mode: AssetPlacerPresenter.Mode):
	mode_label.text = "Mode %s" % str(mode)

func set_axis(vector: Vector3):
	label_3.text = "Axis %s" % str(vector)

func _gui_input(event):
	print("event: %s" % str(event))
