@tool
extends Control

var presenter: AssetPlacerPresenter
var options: AssetPlacerOptions:
	get:
		return AssetPlacerOptionsManager.get_options()

@onready var grid_snapping_checkbox = %GridSnappingCheckbox
@onready var grid_snap_value_spin_box: SpinBox = %GridSnapValueSpinBox
@onready var min_rotation_selector: SpinBoxVector3 = %MinRotationSelector
@onready var max_rotation_selector: SpinBoxVector3 = %MaxRotationSelector

@onready var min_scale_selector: SpinBoxVector3 = %MinScaleSelector
@onready var max_scale_selector: SpinBoxVector3 = %MaxScaleSelector
@onready var uniform_scale_check_box: CheckBox = %UniformScaleCheckBox
@onready var parent_button: Button = %ParentButton
@onready var placement_mode_options_button: OptionButton = %PlacementModeOptionsButton
@onready var plane_axis_spin_box: SpinBoxVector3 = %PlaneAxisSpinBox
@onready var plane_origin_spin_box: SpinBoxVector3 = %PlaneOriginSpinBox
@onready var plane_origin_container: Container = %PlaneOriginContainer
@onready var plane_axis_container: Container = %PlaneAxisContainer
@onready var random_rotation_check_box: CheckBox = %RandomRotationCheckBox
@onready var random_scale_check_box: CheckBox = %RandomScaleCheckBox
@onready var align_normals_checkbox: CheckBox = %AlignNormalsCheckbox
@onready var use_assets_origin_checkbox: CheckBox = %UseAssetsOriginCheckbox
@onready var random_asset_check_box = %RandomAssetCheckBox
@onready var group_automatically_check_box: CheckBox = %GroupAutomaticallyCheckBox
@onready var use_selection_for_parent_check_box: CheckBox = %UseSelectionForParentCheckBox


func _ready():
	presenter = AssetPlacerPresenter.instance
	options.changed.connect(set_options)
	presenter.parent_changed.connect(show_parent)
	presenter.placement_mode_changed.connect(show_placement_mode)

	placement_mode_options_button.item_selected.connect(
		func(id):
			match id:
				0:
					presenter.toggle_surface_placement()
				1:
					presenter.toggle_plane_placement()
				2:
					_show_terrain_3d_selector()
	)

	grid_snapping_checkbox.toggled.connect(options.set_grid_snap_enabled)
	grid_snap_value_spin_box.value_changed.connect(options.set_grid_snap_step)
	random_asset_check_box.toggled.connect(options.set_pick_random_asset)

	random_rotation_check_box.toggled.connect(options.set_use_random_rotation)
	max_rotation_selector.value_changed.connect(options.set_max_random_rotation)
	min_rotation_selector.value_changed.connect(options.set_min_random_rotation)

	random_scale_check_box.toggled.connect(options.set_use_random_scale)
	min_scale_selector.value_changed.connect(options.set_min_random_scale)
	max_scale_selector.value_changed.connect(options.set_max_random_scale)
	uniform_scale_check_box.toggled.connect(options.set_uniform_random_scaling)

	use_assets_origin_checkbox.toggled.connect(options.set_use_asset_origin)
	group_automatically_check_box.toggled.connect(options.set_automatic_grouping)
	use_selection_for_parent_check_box.toggled.connect(options.set_use_selected_as_parent)
	align_normals_checkbox.toggled.connect(options.set_align_normals)

	plane_axis_spin_box.value_changed.connect(
		func(normal: Vector3):
			var plane = PlaneOptions.new(normal, plane_origin_spin_box.get_vector())
			presenter.placement_mode = GapPlacementMode.PlanePlacement.new(plane)
	)

	plane_origin_spin_box.value_changed.connect(
		func(origin: Vector3):
			var plane = PlaneOptions.new(plane_axis_spin_box.get_vector(), origin)
			presenter.placement_mode = GapPlacementMode.PlanePlacement.new(plane)
	)

	parent_button.pressed.connect(
		func(): EditorInterface.popup_node_selector(presenter.select_parent, [&"Node3D"])
	)

	set_options()
	presenter.ready()


func _show_terrain_3d_selector():
	EditorInterface.popup_node_selector(presenter.toggle_terrain_3d_placement, [&"Terrain3D"])


func show_parent(parent: NodePath):
	if options.use_selected_as_parent:
		parent_button.disabled = true
		parent_button.text = "From selection"
		parent_button.icon = EditorIconTexture2D.new("Node3D")
		return
	parent_button.disabled = false
	if not parent.is_empty():
		var scene = EditorInterface.get_edited_scene_root()
		var node = scene.get_node_or_null(parent)
		if node:
			parent_button.text = node.name
			parent_button.icon = EditorIconTexture2D.new(node.get_class())
		else:
			parent_button.text = "Invalid parent path"
			parent_button.icon = EditorIconTexture2D.new("NodeWarning")
	else:
		parent_button.text = "No parent selected"
		parent_button.icon = EditorIconTexture2D.new("NodeWarning")


func show_placement_mode(mode: GapPlacementMode):
	if mode is GapPlacementMode.PlanePlacement:
		placement_mode_options_button.select(1)
		plane_axis_container.show()
		plane_origin_container.show()
		plane_axis_spin_box.set_value_no_signal(mode.plane_options.normal)
		plane_origin_spin_box.set_value_no_signal(mode.plane_options.origin)

	else:
		plane_axis_container.hide()
		plane_origin_container.hide()
	if mode is GapPlacementMode.SurfacePlacement:
		placement_mode_options_button.select(0)
	if mode is GapPlacementMode.Terrain3DPlacement:
		placement_mode_options_button.select(2)


func set_options():
	grid_snapping_checkbox.set_pressed_no_signal(options.grid_snap_enabled)
	grid_snap_value_spin_box.editable = options.grid_snap_enabled
	grid_snap_value_spin_box.set_value_no_signal(options.grid_snap_step)
	random_asset_check_box.set_pressed_no_signal(options.pick_random_asset)

	random_scale_check_box.set_pressed_no_signal(options.use_random_scale)
	min_scale_selector.set_value_no_signal(options.min_random_scale)
	max_scale_selector.set_value_no_signal(options.max_random_scale)
	min_scale_selector.uniform = options.uniform_random_scaling
	max_scale_selector.uniform = options.uniform_random_scaling
	uniform_scale_check_box.set_pressed_no_signal(options.uniform_random_scaling)

	random_rotation_check_box.set_pressed_no_signal(options.use_random_rotation)
	max_rotation_selector.set_value_no_signal(options.max_random_rotation)
	min_rotation_selector.set_value_no_signal(options.min_random_rotation)

	align_normals_checkbox.set_pressed_no_signal(options.align_normals)
	use_assets_origin_checkbox.set_pressed_no_signal(options.use_asset_origin)
	group_automatically_check_box.set_pressed_no_signal(options.group_automatically)
	use_selection_for_parent_check_box.set_pressed_no_signal(options.use_selected_as_parent)
	show_parent(presenter.get_assets_parent_path())
