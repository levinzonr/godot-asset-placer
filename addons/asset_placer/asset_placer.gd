extends RefCounted
class_name AssetPlacer

var preview_node: Node3D
var preview_aabb: AABB
var node_history: Array[String] = []
var preview_rids = []
var asset: AssetResource
var _is_node_transform_mode: bool = false
var _original_transform: Transform3D

var preview_transform_step : float = 0.1
var preview_rotate_step: float = 5

var undo_redo: EditorUndoRedoManager
var meta_asset_id = &"asset_placer_res_id"
var preview_material = load("res://addons/asset_placer/utils/preview_material.tres")

var _strategy: AssetPlacementStrategy 
var _plane_placer: PlanePlacer
var _presenter: AssetPlacerPresenter: 
	get: return AssetPlacerPresenter._instance

func _init(undo_redo: EditorUndoRedoManager, plane_placer: PlanePlacer):
	self.undo_redo = undo_redo
	self._plane_placer = plane_placer


func start_placement(root: Window, asset: AssetResource, placement: PlacementMode):
	stop_placement()
	self.asset = asset
	_is_node_transform_mode = false
	preview_node = _instantiate_asset_resource(asset)
	root.add_child(preview_node)
	preview_rids = get_collision_rids(preview_node)
	set_placement_mode(placement)
	_apply_preview_material(preview_node)
	var scene = EditorInterface.get_selection().get_selected_nodes()[0]
	if scene is Node3D:
		AssetTransformations.apply_transforms(preview_node, AssetPlacerPresenter._instance.options)
		self.preview_aabb = AABBProvider.provide_aabb(preview_node)

func start_node_transform(node: Node3D, placement: PlacementMode):
	stop_placement()
	_is_node_transform_mode = true
	preview_node = node
	_original_transform = node.global_transform
	preview_rids = get_collision_rids(preview_node)
	set_placement_mode(placement)
	self.preview_aabb = AABBProvider.provide_aabb(preview_node)

func _apply_preview_material(node: Node3D):
	if not preview_material:
		return
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
		var normal = Vector3.UP
		
		if AssetPlacerPresenter._instance.options.align_normals and hit:
			normal = hit.normal
			
		var snapped_pos = _snap_position(hit.position, normal)
		var forward_hint = preview_node.global_transform.basis.z
		
		var new_basis = get_safe_basis(normal, forward_hint).scaled(preview_node.scale)
		var new_transform = Transform3D(new_basis, snapped_pos)
		
		var local_bottom = Vector3(0, preview_aabb.position.y, 0)
		
		if _presenter.options.use_asset_origin:
			local_bottom = Vector3.ZERO
		
		var bottom_world = new_transform * local_bottom
		var adjust = snapped_pos - bottom_world
		new_transform.origin += adjust
		preview_node.global_transform = new_transform
		
		return true
	else:
		return false
	
func place_asset(focus_on_placement: bool):
	if preview_node:
		if _is_node_transform_mode:
			_confirm_node_transform()
			return true
		else:
			_place_instance(preview_node.global_transform, focus_on_placement)
			return true
	else:
		return false	

func set_plugin_settings(settings: AssetPlacerSettings):
	preview_rotate_step = settings.rotation_step
	preview_transform_step = settings.transform_step
	if settings.preview_material_resource.is_empty():
		preview_material = null
	else:
		preview_material = load(settings.preview_material_resource)	

func transform_preview(mode: AssetPlacerPresenter.TransformMode, axis: Vector3, direction: int) -> bool:
	if not preview_node:
		return false
		
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
			preview_node.rotate(axis.normalized() * direction, deg_to_rad(preview_rotate_step)) # Can be replaced with deg_to_rad(preview_transform_step) however 0.1 deg is realy low. 
			return true
			
		AssetPlacerPresenter.TransformMode.Move:
			_plane_placer.move_plane_up(direction * 0.2)
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

func _snap_position(hit_pos: Vector3, normal: Vector3) -> Vector3:
	if !AssetPlacerPresenter._instance.options.snapping_enabled:
		return hit_pos

	var grid_step: float = AssetPlacerPresenter._instance.options.snapping_grid_step

	# Build tangent basis aligned to the surface normal
	var n := normal.normalized()
	var tangent := Vector3.UP.cross(n).normalized()
	if tangent.length() < 0.001:
		tangent = Vector3.RIGHT.cross(n).normalized()
	var bitangent := n.cross(tangent).normalized()

	var local_tangent := tangent.dot(hit_pos)
	var local_bitangent := bitangent.dot(hit_pos)
	var local_height := n.dot(hit_pos)

	var snapped_tangent = round(local_tangent / grid_step) * grid_step
	var snapped_bitangent = round(local_bitangent / grid_step) * grid_step

	var snapped = tangent * snapped_tangent \
				   + bitangent * snapped_bitangent \
				   + n * local_height

	return snapped


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
		_presenter.on_asset_placed()

func _do_placement(root: Node3D, transform: Transform3D, select_after_placement: bool):
	var new_node: Node3D =  _instantiate_asset_resource(asset)
	new_node.global_transform = transform
	new_node.transform = root.global_transform.affine_inverse() * transform
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

func _confirm_node_transform():
	if _is_node_transform_mode and preview_node:
		# Create undo action for the node transformation
		undo_redo.create_action("Transform Node: %s" % preview_node.name)
		undo_redo.add_do_method(self, "_do_node_transform", preview_node, preview_node.global_transform)
		undo_redo.add_undo_method(self, "_undo_node_transform", preview_node, _original_transform)
		undo_redo.commit_action()
		
		# Exit node transform mode
		_presenter.end_node_transform_mode()
		stop_placement()

func _do_node_transform(node: Node3D, new_transform: Transform3D):
	node.global_transform = new_transform

func _undo_node_transform(node: Node3D, original_transform: Transform3D):
	node.global_transform = original_transform

func stop_placement():
	self.asset = null
	var was_node_transform_mode = _is_node_transform_mode
	_is_node_transform_mode = false
	if preview_node and not was_node_transform_mode:
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
		_strategy = PlanePlacementStrategy.new(placement_mode.plane_options)
	elif placement_mode is PlacementMode.Terrain3DPlacement:
		_strategy = Terrain3DAssetPlacementStrategy.new(placement_mode.terrain3dNode)
	else:
		push_error("Placement mode %s is not supported" % str(placement_mode))
		
func _pick_name(node: Node3D, parent: Node3D) -> String:
	var number_of_same_scenes = 0
	for child in parent.get_children():
		if child.has_meta(meta_asset_id) && child.get_meta(meta_asset_id) == asset.id:
			number_of_same_scenes += 1
	return node.name if number_of_same_scenes == 0 else node.name + " (%s)" % number_of_same_scenes		


func get_safe_basis(up: Vector3, forward_hint: Vector3) -> Basis:
	up = up.normalized()
	var forward = forward_hint.normalized()

	if abs(up.dot(forward)) > 0.99:
		if abs(up.dot(Vector3.UP)) < 0.9:
			forward = Vector3.UP
		else:
			forward = Vector3.FORWARD

	var right = up.cross(forward).normalized()

	if right.length() < 0.001:
		right = up.cross(Vector3.FORWARD).normalized()
		if right.length() < 0.001:
			right = up.cross(Vector3.RIGHT).normalized()

	forward = right.cross(up).normalized()
	
	if up.length() < 0.001 or right.length() < 0.001 or forward.length() < 0.001:
		return Basis()

	return Basis(right, up, forward).orthonormalized()
