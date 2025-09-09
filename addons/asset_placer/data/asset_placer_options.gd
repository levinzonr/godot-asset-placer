extends RefCounted
class_name AssetPlacerOptions

var snapping_enabled: bool = false
var snapping_grid_step: float = 1.0

var rotate_on_placement: bool = false
var max_rotation: Vector3 = Vector3.UP * 180
var min_rotation: Vector3 = Vector3.ZERO

var scale_on_placement: bool = false
var min_scale: Vector3 = Vector3.ONE
var max_scale: Vector3 = Vector3.ONE * 2
var uniform_scaling: bool = true
