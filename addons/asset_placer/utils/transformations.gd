extends Object
class_name AssetTransformations


static func transform_rotation(transform: Transform3D, options: AssetPlacerOptions) -> Transform3D:
	var rx = randf_range(options.min_rotation.x, options.max_rotation.x)
	transform = transform.rotated(Vector3(1, 0, 0), deg_to_rad(rx))
	var ry = randf_range(options.min_rotation.y, options.max_rotation.y)
	transform = transform.rotated(Vector3(0, 1, 0), deg_to_rad(ry))
	var rz = randf_range(options.min_rotation.z, options.max_rotation.z)
	transform = transform.rotated(Vector3(0, 0, 1), deg_to_rad(rz))
	return transform
