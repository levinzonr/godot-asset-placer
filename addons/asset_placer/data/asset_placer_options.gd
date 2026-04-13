@tool
class_name AssetPlacerOptions
extends Resource


@export_storage var grid_snap_enabled := false: set = set_grid_snap_enabled
@export_storage var grid_snap_step := 1.0: set = set_grid_snap_step

@export_storage var use_asset_origin := true: set = set_use_asset_origin
@export_storage var align_normals := false: set = set_align_normals
@export_storage var pick_random_asset := false: set = set_pick_random_asset

@export_storage var use_random_rotation := false: set = set_use_random_rotation
@export_storage var min_random_rotation := Vector3.ZERO: set = set_min_random_rotation
@export_storage var max_random_rotation := Vector3.UP * 180: set = set_max_random_rotation

@export_storage var use_random_scale := false: set = set_use_random_scale
@export_storage var min_random_scale := Vector3.ONE: set = set_min_random_scale
@export_storage var max_random_scale := Vector3.ONE * 2: set = set_max_random_scale
@export_storage var uniform_random_scaling := true: set = set_uniform_random_scaling

@export_storage var group_automatically := true: set = set_automatic_grouping
@export_storage var use_selected_as_parent := true: set = set_use_selected_as_parent


func set_grid_snap_enabled(value: bool):
	grid_snap_enabled = value
	emit_changed()


func set_grid_snap_step(value: float):
	grid_snap_step = value
	emit_changed()


func set_use_asset_origin(value: bool):
	use_asset_origin = value
	emit_changed()


func set_align_normals(value: bool):
	align_normals = value
	emit_changed()


func set_pick_random_asset(value: bool):
	pick_random_asset = value
	emit_changed()


func set_use_random_rotation(value: bool):
	use_random_rotation = value
	emit_changed()


func set_max_random_rotation(value: Vector3):
	max_random_rotation = value
	emit_changed()


func set_min_random_rotation(value: Vector3):
	min_random_rotation = value
	emit_changed()


func set_use_random_scale(value: bool):
	use_random_scale = value
	emit_changed()


func set_min_random_scale(value: Vector3):
	min_random_scale = value
	emit_changed()


func set_max_random_scale(value: Vector3):
	max_random_scale = value
	emit_changed()


func set_uniform_random_scaling(value: bool):
	uniform_random_scaling = value
	if value:
		min_random_scale = _uniform_v3(min_random_scale.x)
		max_random_scale = _uniform_v3(max_random_scale.x)
	emit_changed()


func set_automatic_grouping(value: bool):
	group_automatically = value
	emit_changed()


func set_use_selected_as_parent(value: bool):
	use_selected_as_parent = value
	emit_changed()


func _uniform_v3(value: float) -> Vector3:
	return Vector3(value, value, value)
