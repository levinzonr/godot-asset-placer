class_name AssetPlacer
extends RefCounted

const META_ASSET_ID = &"asset_placer_res_id"

var preview_node: Node3D
var preview_aabb: AABB
var preview_rids = []
var asset: AssetResource
var preview_transform_step: float = 0.1
var preview_rotate_step: float = 5
var undo_redo: EditorUndoRedoManager
var preview_material = load("res://addons/asset_placer/utils/preview_material.tres")
var brush_decal: Decal
var last_placed_position: Vector3 = Vector3(INF, INF, INF)

var _is_node_transform_mode: bool = false
var _original_transform: Transform3D
var _strategy: AssetPlacementStrategy
var _presenter: AssetPlacerPresenter:
	get:
		return AssetPlacerPresenter.instance


func _init(undo_redo: EditorUndoRedoManager):
	self.undo_redo = undo_redo


func start_placement(root: Window, asset: AssetResource, placement: GapPlacementMode):
	stop_placement()
	self.asset = asset
	_is_node_transform_mode = false
	preview_node = _instantiate_asset_resource(asset)
	root.add_child(preview_node)
	if not brush_decal:
		brush_decal = BrushDecalBuilder.build_decal()
	root.add_child(brush_decal)
	preview_rids = get_collision_rids(preview_node)
	set_placement_mode(placement)
	_apply_preview_material(preview_node)
	var selected := EditorInterface.get_selection().get_selected_nodes()
	if selected.size() == 1 and selected[0] is Node3D and _presenter != null:
		AssetTransformations.apply_transforms(preview_node, _presenter.options)
	self.preview_aabb = AABBProvider.provide_aabb(preview_node)


func start_node_transform(node: Node3D, placement: GapPlacementMode):
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
	if preview_node and _presenter != null:
		var hit = _strategy.get_placement_point(camera, mouse_position)
		var normal = Vector3.UP

		if _presenter.options.align_normals and hit:
			normal = hit.normal

		var snapped_pos = _snap_position(hit.position, normal)
		# Use snapped position to get correct height of terrain.
		if _strategy is Terrain3DAssetPlacementStrategy:
			snapped_pos.y = _strategy.terrain_3d_node.data.get_height(snapped_pos)

		var is_brush_mode = _presenter.options.brush_radius > 0.0

		if brush_decal and is_brush_mode:
			_move_brush_preview(snapped_pos, normal)
		else:
			_move_node_preview(snapped_pos, normal)

		return true
	else:
		return false

func _move_brush_preview(snapped_pos: Vector3, normal: Vector3):
	brush_decal.visible = true
	preview_node.visible = false
	brush_decal.global_position = snapped_pos
	brush_decal.global_transform.basis = get_safe_basis(normal, Vector3.FORWARD)
	var r = _presenter.options.brush_radius
	brush_decal.extents = Vector3(r, 10.0, r)

func _move_node_preview(snapped_pos: Vector3, normal: Vector3):
	preview_node.visible = true
	brush_decal.visible = false
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


func place_asset(focus_on_placement: bool):
	if preview_node and _presenter != null:
		if _is_node_transform_mode:
			_confirm_node_transform()
			return true
		else:
			var is_brush_mode = _presenter.options.brush_radius > 0.0
			var scene := EditorInterface.get_edited_scene_root()
			var scene_root := _presenter.resolve_placement_parent(scene)
			if scene_root == null:
				return false
			var options := _presenter.options
			var parent := AssetParentSelector.pick_parent(scene_root, asset, options.group_automatically)

			if not is_instance_valid(parent) or not is_instance_valid(asset.get_resource()):
				return false

			undo_redo.create_action("Place Asset(s): %s" % asset.name, 0, parent)

			if is_brush_mode:
				_place_brush_instances(parent, focus_on_placement)
			else:
				_spawn_and_record_instance(preview_node.global_transform, parent, focus_on_placement)
				AssetTransformations.apply_transforms(preview_node, _presenter.options)

			undo_redo.commit_action()
			_presenter.on_asset_placed()
			last_placed_position = brush_decal.global_position if is_brush_mode else preview_node.global_position
			return true
	else:
		return false

func should_drag_place() -> bool:
	if not preview_node: return false
	var is_brush_mode = _presenter.options.brush_radius > 0.0
	var current_pos = brush_decal.global_position if is_brush_mode else preview_node.global_position
	
	var spacing = max(preview_aabb.size.x, preview_aabb.size.z)
	if spacing < 0.1: spacing = 0.1 # Minimum spacing safeguard
	
	if is_brush_mode:
		spacing = max(spacing, _presenter.options.brush_radius * 0.5)
		
	return current_pos.distance_to(last_placed_position) >= spacing

func _spawn_and_record_instance(transform: Transform3D, parent: Node3D, select_after_placement: bool):
	var new_node: Node3D = _instantiate_asset_resource(asset)
	new_node.global_transform = transform
	new_node.transform = parent.global_transform.affine_inverse() * transform
	new_node.name = _pick_name(new_node, parent)
	new_node.set_meta(META_ASSET_ID, asset.id)

	undo_redo.add_do_reference(new_node)
	undo_redo.add_do_method(self, "_do_placement", new_node, parent, select_after_placement)
	undo_redo.add_undo_method(self, "_undo_placement", new_node, parent)

func _place_brush_instances(parent: Node3D, focus_on_placement: bool):
	if not brush_decal: return
	var center_pos = brush_decal.global_position
	var brush_normal = brush_decal.global_transform.basis.y
	var radius = _presenter.options.brush_radius
	var density_factor = _presenter.options.brush_density
	
	var amount_to_spawn = 1
	if radius > 0.0:
		var brush_area = PI * radius * radius
		var asset_area = max(0.01, preview_aabb.size.x * preview_aabb.size.z)
		var max_assets = brush_area / asset_area
		amount_to_spawn = max(1, int(round(max_assets * density_factor)))
	
	var tangent = Vector3.UP.cross(brush_normal).normalized()
	if tangent.length() < 0.001:
		tangent = Vector3.RIGHT.cross(brush_normal).normalized()
	var bitangent = brush_normal.cross(tangent).normalized()
	
	var space_state = preview_node.get_world_3d().direct_space_state
	
	for i in range(amount_to_spawn):
		var angle = randf() * TAU
		var r = sqrt(randf()) * radius
		var offset = tangent * (cos(angle) * r) + bitangent * (sin(angle) * r)
		var query_pos = center_pos + offset
		
		var hit_pos = query_pos
		var hit_normal = brush_normal
		
		if _strategy is Terrain3DAssetPlacementStrategy:
			hit_pos.y = _strategy.terrain_3d_node.data.get_height(query_pos)
		else:
			var ray_from = query_pos + brush_normal * 100.0
			var ray_to = query_pos - brush_normal * 100.0
			var params = PhysicsRayQueryParameters3D.new()
			params.from = ray_from
			params.to = ray_to
			params.exclude = preview_rids
			var result = space_state.intersect_ray(params)
			if result.has("position"):
				hit_pos = result.position
				if _presenter.options.align_normals:
					hit_normal = result.normal
				
		var snapped_pos = _snap_position(hit_pos, hit_normal)
		
		var forward_hint = preview_node.global_transform.basis.z
		var new_basis = get_safe_basis(hit_normal, forward_hint).scaled(preview_node.scale)
		var new_transform = Transform3D(new_basis, snapped_pos)
		
		var local_bottom = Vector3(0, preview_aabb.position.y, 0)
		if _presenter.options.use_asset_origin:
			local_bottom = Vector3.ZERO
		var bottom_world = new_transform * local_bottom
		var adjust = snapped_pos - bottom_world
		new_transform.origin += adjust
		
		new_transform = AssetTransformations.transform_rotation(new_transform, _presenter.options)
		new_transform = AssetTransformations.transform_scale(new_transform, _presenter.options)
		
		_spawn_and_record_instance(new_transform, parent, focus_on_placement)


func set_plugin_settings(settings: AssetPlacerSettings):
	preview_rotate_step = settings.rotation_step
	preview_transform_step = settings.transform_step
	if settings.preview_material_resource.is_empty():
		preview_material = null
	else:
		preview_material = load(settings.preview_material_resource)


func transform_preview(
	mode: AssetPlacerPresenter.TransformMode, axis: Vector3, direction: int
) -> bool:
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
			# Can be replaced with deg_to_rad(preview_transform_step) however 0.1 deg is low.
			preview_node.rotate(axis.normalized() * direction, deg_to_rad(preview_rotate_step))
			return true

		AssetPlacerPresenter.TransformMode.Move:
			_presenter.move_plane_up(direction)
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
	if !_presenter.options.snapping_enabled:
		return hit_pos

	var grid_step: float = _presenter.options.snapping_grid_step

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

	var snapped = tangent * snapped_tangent + bitangent * snapped_bitangent + n * local_height

	return snapped


func _do_placement(new_node: Node3D, root: Node3D, select_after_placement: bool):
	var temp_name := new_node.name
	root.add_child(new_node)
	new_node.name = temp_name
	new_node.owner = EditorInterface.get_edited_scene_root()
	if select_after_placement:
		_presenter.clear_selection()
		EditorInterface.edit_node(new_node)


func _undo_placement(new_node: Node3D, root: Node3D):
	root.remove_child(new_node)


func _confirm_node_transform():
	if _is_node_transform_mode and preview_node:
		# Create undo action for the node transformation
		undo_redo.create_action("Transform Node: %s" % preview_node.name, 0, preview_node)
		undo_redo.add_do_method(
			self, "_do_node_transform", preview_node, preview_node.global_transform
		)
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
	last_placed_position = Vector3(INF, INF, INF)
	if brush_decal:
		brush_decal.queue_free()
		brush_decal = null


func _instantiate_asset_resource(asset: AssetResource) -> Node3D:
	var new_node: Node3D
	var resource := asset.get_resource()
	if resource is PackedScene:
		new_node = (resource.instantiate() as Node3D)
	elif resource is ArrayMesh:
		new_node = MeshInstance3D.new()
		new_node.name = asset.name
		new_node.mesh = resource.duplicate()
	else:
		push_error("Not supported resource type %s" % str(resource))

	return new_node


func set_placement_mode(placement_mode: GapPlacementMode):
	if placement_mode is GapPlacementMode.SurfacePlacement:
		_strategy = SurfaceAssetPlacementStrategy.new(preview_rids)
	elif placement_mode is GapPlacementMode.PlanePlacement:
		_strategy = PlanePlacementStrategy.new(placement_mode.plane_options)
	elif placement_mode is GapPlacementMode.Terrain3DPlacement:
		_strategy = Terrain3DAssetPlacementStrategy.new(placement_mode.get_terrain_3d_node())
	else:
		push_error("Placement mode %s is not supported" % str(placement_mode))


func _pick_name(node: Node3D, parent: Node3D) -> String:
	var number_of_same_scenes := 0
	for child in parent.get_children():
		if child.has_meta(META_ASSET_ID) && child.get_meta(META_ASSET_ID) == asset.id:
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
