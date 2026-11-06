class_name PlanePlacementStrategy
extends AssetPlacementStrategy

var plane_options: PlaneOptions


func _init(plane_options: PlaneOptions):
	self.plane_options = plane_options


func get_placement_point(
	camera: Camera3D, mouse_position: Vector2
) -> AssetPlacementStrategy.CollisionHit:
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_dir = camera.project_ray_normal(mouse_position)

	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		return _get_ortho_placement_point(ray_origin, ray_dir)
	else:
		return _get_perspective_placement_point(ray_origin, ray_dir)


func _get_perspective_placement_point(
	ray_origin: Vector3, ray_dir: Vector3
) -> AssetPlacementStrategy.CollisionHit:
	var normal = plane_options.normal
	var origin = plane_options.origin

	if abs(ray_dir.dot(normal)) < 0.01:
		normal = -ray_dir.normalized()

	var plane = Plane(normal, origin)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)
	return _create_collision_hit(plane, ray_dir, intersection)


func _get_ortho_placement_point(
	ray_origin: Vector3, ray_dir: Vector3
) -> AssetPlacementStrategy.CollisionHit:
	var normal = plane_options.normal
	var origin = plane_options.origin

	if abs(ray_dir.dot(normal)) < 0.01:
		var abs_dir = ray_dir.abs()
		if abs_dir.y >= abs_dir.x and abs_dir.y >= abs_dir.z:
			normal = Vector3.UP
		elif abs_dir.z >= abs_dir.x:
			normal = Vector3.BACK
		else:
			normal = Vector3.RIGHT

	var plane = Plane(normal, origin)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)
	if not intersection:
		plane = Plane(-ray_dir.normalized(), origin)
		intersection = plane.intersects_ray(ray_origin, ray_dir)

	return _create_collision_hit(plane, ray_dir, intersection)


func _create_collision_hit(
	plane: Plane, ray_dir: Vector3, intersection
) -> AssetPlacementStrategy.CollisionHit:
	if intersection:
		var final_normal = plane.normal
		if ray_dir.dot(plane.normal) > 0:
			final_normal = -plane.normal
		return AssetPlacementStrategy.CollisionHit.new(intersection, final_normal)
	else:
		return AssetPlacementStrategy.CollisionHit.zero()
