extends AssetPlacementStrategy
class_name SurfaceAssetPlacementStrategy

var exclude_rids = []

func _init(exclude_rids):
	self.exclude_rids = exclude_rids

func get_placement_point(camera: Camera3D, mouse_position: Vector2) -> CollisionHit:
	var ray_origin = camera.project_ray_origin(mouse_position)
	var	ray_dir = camera.project_ray_normal(mouse_position)
	var space_state = camera.get_world_3d().direct_space_state

	var params = PhysicsRayQueryParameters3D.new()
	params.from = ray_origin
	params.exclude = exclude_rids
	params.to = ray_origin + ray_dir * 1000
	var result = space_state.intersect_ray(params)
	if not result.has('position') or not result.has('normal'):
		AssetPlacerPresenter._instance.show_error.emit("No Surface to Collide With")
		return AssetPlacementStrategy.CollisionHit.zero()

	var position: Vector3 = result.position
	var normal: Vector3 = result.normal
	return AssetPlacementStrategy.CollisionHit.new(position, normal)
