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

func _ready():
	presenter = AssetPlacerPresenter._instance
	presenter.options_changed.connect(set_options)
	presenter.parent_changed.connect(show_parent)
	presenter.placement_mode_changed.connect(func(m):
		if m is PlacementMode.PlanePlacement:
			placement_mode_options_button.select(1)
		if m is PlacementMode.SurfacePlacement:
			placement_mode_options_button.select(0)
		if m is PlacementMode.Terrain3DPlacement:
			placement_mode_options_button.select(2)
	)
	
	placement_mode_options_button.item_selected.connect(func(id):
		match id:
			0: presenter.toggle_surface_placement()
			1: presenter.toggle_plane_placement()
			2: _show_terrain_3d_selector()
	)
	
	grid_snapping_checkbox.toggled.connect(presenter.set_grid_snapping_enabled)
	grid_snap_value_spin_box.value_changed.connect(presenter.set_grid_snap_value)
	random_asset_check_box.toggled.connect(presenter.set_random_asset_enabled)
	max_rotation_selector.value_changed.connect(presenter.set_max_rotation)
	min_rotation_selector.value_changed.connect(presenter.set_min_rotation)
	min_scale_selector.value_changed.connect(presenter.set_min_scale)
	max_scale_selector.value_changed.connect(presenter.set_max_scale)
	uniform_scale_check_box.toggled.connect(presenter.set_unform_scaling)
	use_assets_origin_checkbox.toggled.connect(presenter.set_use_asset_origin)
	
	plane_axis_spin_box.value_changed.connect(func(normal: Vector3):
		var plane = PlaneOptions.new(normal, plane_origin_spin_box.get_vector())
		presenter.placement_mode = PlacementMode.PlanePlacement.new(plane)
	)
	
	plane_origin_spin_box.value_changed.connect(func(origin: Vector3):
		var plane = PlaneOptions.new(plane_axis_spin_box.get_vector(), origin)	
		presenter.placement_mode = PlacementMode.PlanePlacement.new(plane)
	)
	
	presenter.placement_mode_changed.connect(func(mode: PlacementMode):
		if mode is PlacementMode.PlanePlacement:
			plane_axis_container.show()
			plane_origin_container.show()
			plane_axis_spin_box.set_value_no_signal(mode.plane_options.normal)
			plane_origin_spin_box.set_value_no_signal(mode.plane_options.origin)
		else:
			plane_axis_container.hide()
			plane_origin_container.hide()	
		)
	
	parent_button.pressed.connect(func():
		EditorInterface.popup_node_selector(presenter.select_parent, [&"Node3D"])
	)
	
	random_rotation_check_box.toggled.connect(presenter.set_random_rotation_enabled)
	random_scale_check_box.toggled.connect(presenter.set_random_scale_enabled)
	align_normals_checkbox.toggled.connect(presenter.set_align_normals)
	presenter.ready()

func _show_terrain_3d_selector():
	EditorInterface.popup_node_selector(presenter.toggle_terrain_3d_placement, [&"Terrain3D"])

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
	random_asset_check_box.set_pressed_no_signal(options.enable_random_placement)
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
	random_rotation_check_box.set_pressed_no_signal(options.rotate_on_placement)
	random_scale_check_box.set_pressed_no_signal(options.scale_on_placement)
	align_normals_checkbox.set_pressed_no_signal(options.align_normals)
	use_assets_origin_checkbox.set_pressed_no_signal(options.use_asset_origin)
