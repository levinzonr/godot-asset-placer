extends Object
class_name AssetTransformations


static func transform_rotation(transform: Transform3D, options: AssetPlacerOptions) -> Transform3D:
	if options.transform_rotate_x:
		var rx = randf_range(0, TAU)
		transform = transform.rotated(Vector3(1, 0, 0), rx)
	if options.transform_rotate_y:
		var ry = randf_range(0, TAU)
		transform = transform.rotated(Vector3(0, 1, 0), ry)
	if options.transform_rotate_z:
		var rz = randf_range(0, TAU)
		transform = transform.rotated(Vector3(0, 0, 1), rz)
	return transform
