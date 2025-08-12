@tool
extends Control

var presenter: AssetPlacerPresenter
@onready var grid_snapping_checkbox = %GridSnappingCheckbox
@onready var grid_snap_value_spin_box: SpinBox = %GridSnapValueSpinBox
@onready var min_rotation_selector: SpinBoxVector3 = %MinRotationSelector
@onready var max_rotation_selector: SpinBoxVector3 = %MaxRotationSelector

@onready var min_scale_selector: SpinBoxVector3 = %MinScaleSelector
@onready var max_scale_selector: SpinBoxVector3 = %MaxScaleSelector
@onready var uniform_scale_check_box: CheckBox = %UniformScaleCheckBox
@onready var parent_button: Button = %ParentButton
func _ready():
	presenter = AssetPlacerPresenter._instance
	presenter.options_changed.connect(set_options)
	presenter.parent_changed.connect(show_parent)
	presenter.ready()
	
	grid_snapping_checkbox.toggled.connect(presenter.set_grid_snapping_enabled)
	grid_snap_value_spin_box.value_changed.connect(presenter.set_grid_snap_value)
	
	max_rotation_selector.value_changed.connect(presenter.set_max_rotation)
	min_rotation_selector.value_changed.connect(presenter.set_min_rotation)
	min_scale_selector.value_changed.connect(presenter.set_min_scale)
	max_scale_selector.value_changed.connect(presenter.set_max_scale)
	uniform_scale_check_box.toggled.connect(presenter.set_unform_scaling)
	
	parent_button.pressed.connect(func():
		EditorInterface.popup_node_selector(presenter.select_parent, [&"Node3D"])
	)


func show_parent(parent: NodePath):
	if not parent.is_empty():
		var scene = EditorInterface.get_edited_scene_root()
		var node = scene.get_node(parent)
		parent_button.text = node.name
		parent_button.icon = EditorIconTexture2D.new(node.get_class())
	else:
		parent_button.text = "No parent selected"
		parent_button.icon = EditorIconTexture2D.new("NodeWarning")

func set_options(options: AssetPlacerOptions):
	grid_snapping_checkbox.set_pressed_no_signal(options.snapping_enabled)
	grid_snap_value_spin_box.editable = options.snapping_enabled
	grid_snap_value_spin_box.set_value_no_signal(options.snapping_grid_step)
	max_rotation_selector.set_value_no_signal(options.max_rotation)
	min_rotation_selector.set_value_no_signal(options.min_rotation)
	min_scale_selector.set_value_no_signal(options.min_scale)
	max_scale_selector.set_value_no_signal(options.max_scale)
	min_scale_selector.uniform = options.uniform_scaling
	max_scale_selector.uniform = options.uniform_scaling
	uniform_scale_check_box.set_pressed_no_signal(options.uniform_scaling)
	
