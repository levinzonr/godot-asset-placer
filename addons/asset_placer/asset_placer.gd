extends RefCounted
class_name AssetPlacer

var preview_node: Node3D
var preview_aabb: AABB
var asset: AssetResource

func start_placement(root: Window, asset: AssetResource):
	stop_placement()
	self.asset = asset
	preview_node = asset.scene.instantiate()
	self.preview_aabb = AABBProvider.provide_aabb(preview_node)
	root.add_child(preview_node)
	var scene = EditorInterface.get_edited_scene_root()
	if scene is Node3D:
		EditorInterface.get_selection().add_node(scene)
	
func handle_3d_input(camera: Camera3D, event: InputEvent) -> bool:
	
	if  preview_node:
		if event is InputEventMouseMotion:
			var ray_origin = camera.project_ray_origin(event.position)
			var ray_dir = camera.project_ray_normal(event.position)
			var space_state = camera.get_world_3d().direct_space_state

			var params = PhysicsRayQueryParameters3D.new()
			params.from = ray_origin
			params.to = ray_origin + ray_dir * 1000
			var result = space_state.intersect_ray(params)
			if result: 
				var snapped_pos = result.position
				var base_y = preview_aabb.position.y
				preview_node.global_transform.origin = snapped_pos - Vector3(0, base_y, 0)


		elif event is InputEventMouseButton and event.pressed:
			_place_instance(preview_node.global_transform)
			return true

	return false
	
	
	
func _place_instance(transform: Transform3D):
	var scene_root = EditorInterface.get_edited_scene_root()
	if scene_root and asset.scene:
		var new_node =  asset.scene.instantiate()
		new_node.transform = transform
		scene_root.add_child(new_node)
		new_node.owner = scene_root
		EditorInterface.get_selection().clear()
		EditorInterface.get_selection().add_node(new_node)
		stop_placement()
	
func stop_placement():
	self.asset = null
	if preview_node:
		preview_node.queue_free()
		preview_node = null
		
func pause_placement():
	if preview_node:
		preview_node.hide()

func resume_placement():
	if preview_node:
		preview_node.show()	
