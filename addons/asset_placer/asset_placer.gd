extends RefCounted
class_name AssetPlacer

var preview_node: Node3D
var preview_aabb: AABB
var node_history: Array[String] = []
var preview_rids = []
var asset: AssetResource

var preview_material = load("res://addons/asset_placer/utils/preview_material.tres")

func start_placement(root: Window, asset: AssetResource):
	self.asset = asset
	preview_node = (asset.scene.instantiate() as Node3D).duplicate()
	root.add_child(preview_node)
	preview_rids = get_collision_rids(preview_node)
	_apply_preview_material(preview_node)
	var scene = EditorInterface.get_selection().get_selected_nodes()[0]
	if scene is Node3D:
		AssetTransformations.apply_transforms(preview_node, AssetPlacerPresenter._instance.options)
		self.preview_aabb = AABBProvider.provide_aabb(preview_node)

func _apply_preview_material(node: Node3D):
	for child in node.get_children():
		if child is MeshInstance3D:
			for i in child.get_surface_override_material_count():
				print("Set material")
				child.set_surface_override_material(i, preview_material)
		_apply_preview_material(child)
		

func handle_3d_input(camera: Camera3D, event: InputEvent) -> bool:

	if EditorInterface.get_edited_scene_root() is not Node3D:
			pass

	if  preview_node:
		if event is InputEventMouseMotion:
			var ray_origin = camera.project_ray_origin(event.position)
			var	 ray_dir = camera.project_ray_normal(event.position)
			var space_state = camera.get_world_3d().direct_space_state

			var params = PhysicsRayQueryParameters3D.new()
			params.from = ray_origin
			params.exclude = preview_rids
			params.to = ray_origin + ray_dir * 1000
			var result = space_state.intersect_ray(params)
			if result:
				var snapped_pos = _snap_position(result.position)

				preview_node.global_transform.origin = snapped_pos
				preview_node.force_update_transform()
				preview_aabb = AABBProvider.provide_aabb(preview_node)

				var bottom_y = preview_aabb.position.y

				var y_offset = snapped_pos.y - bottom_y

				var new_origin = preview_node.global_transform.origin
				new_origin.y += y_offset
				preview_node.global_transform.origin = new_origin



		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_place_instance(preview_node.global_transform)
				return true
			else:
				return false

	return false

func get_collision_rids(node: Node) -> Array:
	var rids = []
	for child in node.get_children():
		if child is CollisionObject3D:
			rids.append(child.get_rid())
		rids += get_collision_rids(child)
	return rids

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
	var selection = EditorInterface.get_selection()
	var scene_root = selection.get_selected_nodes()[0]
	if scene_root and asset.scene:
		var undoredo = EditorInterface.get_editor_undo_redo()
		undoredo.create_action("Place Asset: %s" % asset.name)
		undoredo.add_do_method(self, "_do_placement", scene_root, transform)
		undoredo.add_undo_method(self, "_undo_placement", scene_root)
		undoredo.commit_action()
		AssetTransformations.apply_transforms(preview_node, AssetPlacerPresenter._instance.options)

func _do_placement(root: Node3D, transform: Transform3D):
	var new_node: Node3D =  asset.scene.instantiate()
	new_node.global_transform = transform
	new_node.position = root.to_local(transform.origin)
	root.add_child(new_node)
	new_node.owner = EditorInterface.get_edited_scene_root()
	node_history.push_front(new_node.name)

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
		
