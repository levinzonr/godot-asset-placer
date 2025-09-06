extends AssetPlacementStrategy
class_name Terrain3DAssetPlacementStrategy

var terrain_3d_node: Node3D

func _init(node: Node3D):
	self.terrain_3d_node = node

func get_placement_point(
	camera: Camera3D, 
	mouse_position: Vector2
) -> CollisionHit:
	if terrain_3d_node.has_method("get_intersection"):
		var from := camera.project_ray_origin(mouse_position)
		var to := from + camera.project_ray_normal(mouse_position) * 1000
		var direction = (to - from).normalized()
		var hit_position: Vector3 = terrain_3d_node.get_intersection(from, direction, false)
		if hit_position != Vector3.INF:
			var data = terrain_3d_node.data
			var normal = data.get_normal(hit_position)
			return CollisionHit.new(hit_position, normal)
		else:
			var message := "No collision with Terrain3D"
			AssetPlacerPresenter._instance.show_error.emit(message)
			return CollisionHit.zero()
	else:
		push_error("Provided Node is Not Terrain3D")
		return CollisionHit.zero()
