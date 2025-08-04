extends RefCounted
class_name AssetPlacer

var preview_node: Node3D
var preview_aabb: AABB
var node_history: Array[String] = []
var asset: AssetResource

func start_placement(root: Window, asset: AssetResource):
	self.asset = asset
	preview_node = asset.scene.instantiate()
	self.preview_aabb = AABBProvider.provide_aabb(preview_node)
	root.add_child(preview_node)
	var scene = AssetContextProvider.resolve_current_context()
	if scene is Node3D:
		preview_node.global_transform = AssetTransformations.transform_rotation(preview_node.global_transform, AssetPlacerPresenter._instance.options)
		
	
func handle_3d_input(camera: Camera3D, event: InputEvent) -> bool:
	
	if EditorInterface.get_edited_scene_root() is not Node3D:
		pass
	
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
				var snapped_pos = _snap_position(result.position)
				var base_y = preview_aabb.position.y
				preview_node.global_transform.origin = snapped_pos - Vector3(0, base_y, 0)


		elif event is InputEventMouseButton and event.pressed:
			_place_instance(preview_node.global_transform)
			return true

	return false
	
func _snap_position(pos: Vector3):
	if !AssetPlacerPresenter._instance.options.snapping_enabled:
		return pos
	var grid_step: float = AssetPlacerPresenter._instance.options.snapping_grid_step
	return Vector3(
		round(pos.x / grid_step) * grid_step,
		round(pos.y / grid_step) * grid_step,
		round(pos.z / grid_step) * grid_step
	)
	
func _place_instance(transform: Transform3D):
	var scene_root = EditorInterface.get_edited_scene_root()
	print("Place ata" +str(scene_root.name))
	if scene_root and asset.scene:
		var undoredo = EditorInterface.get_editor_undo_redo()
		undoredo.create_action("Place Asset")
		undoredo.add_do_method(self, "_do_placement", scene_root, transform)
		undoredo.add_undo_method(self, "_undo_placement", scene_root)
		undoredo.commit_action()
		preview_node.global_transform = AssetTransformations.transform_rotation(preview_node.global_transform, AssetPlacerPresenter._instance.options)

func _do_placement(root: Node3D, transform: Transform3D):
	var new_node =  asset.scene.instantiate()
	new_node.transform = transform
	root.add_child(new_node)
	new_node.owner = root
	node_history.push_back(new_node.name)

func _undo_placement(root: Node3D):
	var last_added = node_history.pop_front()
	var node_index = root.get_children().find_custom(func(a): return a.name == last_added)
	var node = root.get_child(node_index)
	node.queue_free()
	

func stop_placement():
	self.asset = null
	if preview_node:
		preview_node.queue_free()
		preview_node = null
		
