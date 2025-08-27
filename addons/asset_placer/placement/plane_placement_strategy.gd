extends AssetPlacementStrategy
class_name PlanePlacementStrategy

var plane: Plane


func _init(plane: Plane):
	self.plane = plane
	
	
func get_placement_point(camera: Camera3D, mouse_position: Vector2) -> AssetPlacementStrategy.CollisionHit:
	var ray_origin = camera.project_ray_origin(mouse_position)
	var	ray_dir = camera.project_ray_normal(mouse_position)
	var intersection = plane.intersects_ray(ray_origin, ray_dir)
	if intersection:
		return AssetPlacementStrategy.CollisionHit.new(intersection, plane.normal)
	else:
		return AssetPlacementStrategy.CollisionHit.ZERO
	
