extends RefCounted
class_name AssetPlacer

var preview_node: Node3D
var preview_aabb: AABB
var node_history: Array[String] = []
var preview_rids = []
var asset: AssetResource

var preview_transform_step : float = 0.1

var undo_redo: EditorUndoRedoManager
var meta_asset_id = &"asset_placer_res_id"
var preview_material = load("res://addons/asset_placer/utils/preview_material.tres")

var _strategy: AssetPlacementStrategy 

func _init(undo_redo: EditorUndoRedoManager):
	self.undo_redo = undo_redo


func start_placement(root: Window, asset: AssetResource, placement: PlacementMode):
	stop_placement()
	self.asset = asset
	preview_node = _instantiate_asset_resource(asset)
	root.add_child(preview_node)
	preview_rids = get_collision_rids(preview_node)
	set_placement_mode(placement)
	_apply_preview_material(preview_node)
	var scene = EditorInterface.get_selection().get_selected_nodes()[0]
	if scene is Node3D:
		AssetTransformations.apply_transforms(preview_node, AssetPlacerPresenter._instance.options)
		self.preview_aabb = AABBProvider.provide_aabb(preview_node)

func _apply_preview_material(node: Node3D):
	
	if node is MeshInstance3D:
		for i in node.get_surface_override_material_count():
			node.set_surface_override_material(i, preview_material)
	
	for child in node.get_children():
		if child is MeshInstance3D:
			for i in child.get_surface_override_material_count():
				child.set_surface_override_material(i, preview_material)
		_apply_preview_material(child)
		

func move_preview(mouse_position: Vector2, camera: Camera3D) -> bool:
	if preview_node:
		var hit = _strategy.get_placement_point(camera, mouse_position)
		var snapped_pos = _snap_position(hit.position)
		
		var up = hit.normal.normalized()
		var forward = preview_node.global_transform.basis.z
		
		if abs(up.dot(forward)) > 0.99:
			forward = Vector3.FORWARD  # safe fallback
		
		var right = up.cross(forward).normalized()
		forward = right.cross(up).normalized()
		var new_basis = Basis(right, up, forward)
		
		var new_transform = Transform3D(new_basis, snapped_pos)
		preview_node.global_transform = new_transform
		
		preview_aabb = AABBProvider.provide_aabb(preview_node)
		var bottom_y = preview_aabb.position.y
		var y_offset = snapped_pos.y - bottom_y
		
		var new_origin = snapped_pos
		new_origin.y += y_offset
		preview_node.global_transform.origin = new_origin
		
		return true
	else:
		return false
	
func place_asset(focus_on_placement: bool):
	if preview_node:
		_place_instance(preview_node.global_transform, focus_on_placement)
		return true
	else:
		return false	


func transform_preview(mode: AssetPlacerPresenter.TransformMode, axis: Vector3, direction: int) -> bool:
	match mode:
		AssetPlacerPresenter.TransformMode.None:
			return false
		AssetPlacerPresenter.TransformMode.Scale:
			var factor := 1.0 + preview_transform_step * direction
			var min_scale := 0.01
			var new_scale := preview_node.scale
			if axis.x != 0:
				new_scale.x = max(preview_node.scale.x * factor, min_scale)
			if axis.y != 0:
				new_scale.y = max(preview_node.scale.y * factor, min_scale)
			if axis.z != 0:
				new_scale.z = max(preview_node.scale.z * factor, min_scale)
			preview_node.scale = new_scale
			return true
		AssetPlacerPresenter.TransformMode.Rotate:
			preview_node.rotate(axis.normalized() * direction, preview_transform_step)
			return true
			
		AssetPlacerPresenter.TransformMode.Move:
			preview_node.translate(axis.normalized() * direction * preview_transform_step)
			return true
		_:
			return false

func get_collision_rids(node: Node) -> Array:
	var rids = []
	if node is CollisionObject3D:
		rids.append(node.get_rid())
	for child in node.get_children():
		rids += get_collision_rids(child)
	return rids

func _snap_position(pos: Vector3):
	if !AssetPlacerPresenter._instance.options.snapping_enabled:
		return pos
	var grid_step: float = AssetPlacerPresenter._instance.options.snapping_grid_step
	return pos.snapped(Vector3(grid_step, grid_step, grid_step))

func _place_instance(transform: Transform3D, select_after_placement: bool):
	var selection = EditorInterface.get_selection()
	var scene = EditorInterface.get_edited_scene_root()
	var scene_root = scene.get_node(AssetPlacerPresenter._instance._parent)
	
	if scene_root and asset.scene:
		undo_redo.create_action("Place Asset: %s" % asset.name)
		undo_redo.add_do_method(self, "_do_placement", scene_root, transform, select_after_placement)
		undo_redo.add_undo_method(self, "_undo_placement", scene_root)
		undo_redo.commit_action()
		AssetTransformations.apply_transforms(preview_node, AssetPlacerPresenter._instance.options)

func _do_placement(root: Node3D, transform: Transform3D, select_after_placement: bool):
	var new_node: Node3D =  _instantiate_asset_resource(asset)
	new_node.global_transform = transform
	new_node.position = root.to_local(transform.origin)
	new_node.set_meta(meta_asset_id, asset.id)
	new_node.name = _pick_name(new_node, root)
	root.add_child(new_node)
	new_node.owner = EditorInterface.get_edited_scene_root()
	node_history.push_front(new_node.name)
	if select_after_placement:
		AssetPlacerPresenter._instance.clear_selection()
		EditorInterface.edit_node(new_node)

func _undo_placement(root: Node3D):
	var last_added = node_history.pop_front()
	var children = root.get_children()
	var node_index = -1; for a in root.get_child_count(): if children[a].name == last_added: node_index = a; break
	var node = root.get_child(node_index)
	node.queue_free()

func stop_placement():
	self.asset = null
	if preview_node:
		preview_node.queue_free()
		preview_node = null
		

func _instantiate_asset_resource(asset: AssetResource) -> Node3D:
	var _preview_node: Node3D
	if asset.scene is PackedScene:
		_preview_node = (asset.scene.instantiate() as Node3D).duplicate()
	elif asset.scene is ArrayMesh:
		_preview_node = MeshInstance3D.new()
		_preview_node.name = asset.name
		_preview_node.mesh = asset.scene.duplicate()
	else:
		push_error("Not supported resource type %s" % str(asset.scene))
	
	return _preview_node

func set_placement_mode(placement_mode: PlacementMode):
	if placement_mode is PlacementMode.SurfacePlacement:
		_strategy = SurfaceAssetPlacementStrategy.new(preview_rids)
	elif placement_mode is PlacementMode.PlanePlacement:
		_strategy = PlanePlacementStrategy.new(placement_mode.plane)
	else:
		push_error("Placement mode %s is not supported" % str(placement_mode))
		
func _pick_name(node: Node3D, parent: Node3D) -> String:
	var number_of_same_scenes = 0
	for child in parent.get_children():
		if child.has_meta(meta_asset_id) && child.get_meta(meta_asset_id) == asset.id:
			number_of_same_scenes += 1
	return node.name if number_of_same_scenes == 0 else node.name + " (%s)" % number_of_same_scenes		
