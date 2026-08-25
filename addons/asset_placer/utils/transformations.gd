class_name AssetTransformations
extends Object


static func apply_transforms(node: Node3D, options: AssetPlacerOptions, rng: RandomNumberGenerator):
	node.global_transform = transform_rotation(node.global_transform, options, rng)
	node.global_transform = transform_scale(node.global_transform, options, rng)


static func transform_rotation(
	transform: Transform3D, options: AssetPlacerOptions, rng: RandomNumberGenerator
) -> Transform3D:
	if not options.use_random_rotation:
		return transform

	var rx = rng.randf_range(options.min_random_rotation.x, options.max_random_rotation.x)
	transform = transform.rotated_local(Vector3(1, 0, 0), deg_to_rad(rx))
	var ry = rng.randf_range(options.min_random_rotation.y, options.max_random_rotation.y)
	transform = transform.rotated_local(Vector3(0, 1, 0), deg_to_rad(ry))
	var rz = rng.randf_range(options.min_random_rotation.z, options.max_random_rotation.z)
	transform = transform.rotated_local(Vector3(0, 0, 1), deg_to_rad(rz))
	return transform


static func transform_scale(
	transform: Transform3D, options: AssetPlacerOptions, rng: RandomNumberGenerator
) -> Transform3D:
	if not options.use_random_scale:
		return transform

	if options.uniform_random_scaling:
		var scale = rng.randf_range(options.min_random_scale.x, options.max_random_scale.x)
		var basis = transform.basis.orthonormalized().scaled(Vector3(scale, scale, scale))
		transform.basis = basis
		return transform
	else:
		var scale_x = rng.randf_range(options.min_random_scale.x, options.max_random_scale.x)
		var scale_y = rng.randf_range(options.min_random_scale.y, options.max_random_scale.y)
		var scale_z = rng.randf_range(options.min_random_scale.z, options.max_random_scale.z)
		var basis = transform.basis.orthonormalized().scaled(Vector3(scale_x, scale_y, scale_z))
		transform.basis = basis
		return transform


static func make_uniform(v: Vector3) -> Vector3:
	var avg = (v.x + v.y + v.z) / 3.0
	return Vector3(avg, avg, avg)
