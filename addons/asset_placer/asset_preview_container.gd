class_name AssetPreviewContainer extends Node3D

var asset: AssetResource
var options: AssetPlacerOptions
var preview_aabb: AABB
var preview_rids: Array
var preview_material: Material
var _manual_scale := Vector3.ONE
var _manual_rotation := Basis()
var _stroke_id: int = 0


func init(p_asset: AssetResource, p_options: AssetPlacerOptions, p_material: Material) -> void:
	self.asset = p_asset
	self.options = p_options
	self.preview_material = p_material
	self.name = "PreviewContainer"

	var initial_instance = _instantiate_asset_resource(asset)
	self.preview_aabb = AABBProvider.provide_aabb(initial_instance)
	self.add_child(initial_instance)
	self.preview_rids = _get_collision_rids(self)
	_apply_preview_material(initial_instance)


func update_preview(snapped_pos: Vector3, normal: Vector3, is_brush_mode: bool) -> void:
	var r = options.brush_radius
	var amount_to_spawn = 1

	if is_brush_mode and r > 0.0:
		var density_factor = options.brush_density
		var brush_area = PI * r * r
		var asset_area = max(0.25, preview_aabb.size.x * preview_aabb.size.z)
		var max_assets = (brush_area / asset_area) * 0.2
		var curved_density = pow(density_factor, 2.0)
		amount_to_spawn = max(1, int(round(max_assets * curved_density)))

	_sync_preview_children(amount_to_spawn, is_brush_mode)

	var forward_hint = global_transform.basis.z
	var new_basis = _get_safe_basis(normal, forward_hint).scaled(self.scale)
	var new_transform = Transform3D(new_basis, snapped_pos)

	var local_bottom = Vector3(0, preview_aabb.position.y, 0)
	if options.use_asset_origin:
		local_bottom = Vector3.ZERO

	var bottom_world = new_transform * local_bottom
	var adjust = snapped_pos - bottom_world
	new_transform.origin += adjust
	self.global_transform = new_transform


func _sync_preview_children(count: int, is_brush: bool) -> void:
	var current_children = get_children()
	if current_children.size() != count:
		for child in current_children:
			child.queue_free()

		var rng = RandomNumberGenerator.new()
		rng.seed = _stroke_id

		for i in range(count):
			var new_child = _instantiate_asset_resource(asset)
			add_child(new_child)
			_apply_preview_material(new_child)

			if not is_brush:
				var new_transform = Transform3D(_manual_rotation, Vector3.ZERO)
				new_transform.basis = new_transform.basis.scaled(_manual_scale)
				new_child.transform = new_transform
			else:
				var radius = options.brush_radius
				var angle = rng.randf() * TAU
				var r = sqrt(rng.randf()) * radius
				var local_pos = Vector3(cos(angle) * r, 0, sin(angle) * r)

				var new_transform = Transform3D(Basis(), local_pos)
				new_transform = AssetTransformations.transform_rotation(new_transform, options, rng)
				new_transform = AssetTransformations.transform_scale(new_transform, options, rng)

				new_transform.basis = new_transform.basis * _manual_rotation
				new_transform.basis = new_transform.basis.scaled(_manual_scale)

				new_child.transform = new_transform


func apply_manual_transform(
	axis: Vector3, direction: int, transform_step: float, rotate_step: float, is_scale: bool
) -> void:
	if is_scale:
		var factor := 1.0 + transform_step * direction
		var min_scale := 0.01

		if axis.x != 0:
			_manual_scale.x = max(_manual_scale.x * factor, min_scale)
		if axis.y != 0:
			_manual_scale.y = max(_manual_scale.y * factor, min_scale)
		if axis.z != 0:
			_manual_scale.z = max(_manual_scale.z * factor, min_scale)

		for child in get_children():
			var new_scale = child.scale
			if axis.x != 0:
				new_scale.x = max(new_scale.x * factor, min_scale)
			if axis.y != 0:
				new_scale.y = max(new_scale.y * factor, min_scale)
			if axis.z != 0:
				new_scale.z = max(new_scale.z * factor, min_scale)
			child.scale = new_scale
	else:
		var rot_axis = axis.normalized() * direction
		var rot_angle = deg_to_rad(rotate_step)
		_manual_rotation = _manual_rotation.rotated(rot_axis, rot_angle)

		for child in get_children():
			child.rotate(rot_axis, rot_angle)


func force_next_stroke() -> void:
	_stroke_id += 1
	for child in get_children():
		child.queue_free()


func get_children_transforms() -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	for child in get_children():
		transforms.append(child.global_transform)
	return transforms


func _instantiate_asset_resource(p_asset: AssetResource) -> Node3D:
	return p_asset.get_resource().instantiate() as Node3D


func _apply_preview_material(node: Node) -> void:
	if preview_material == null:
		return
	if node is MeshInstance3D:
		var mat_count = node.get_surface_override_material_count()
		for i in range(mat_count):
			node.set_surface_override_material(i, preview_material)
	for child in node.get_children():
		_apply_preview_material(child)


func _get_collision_rids(node: Node) -> Array:
	var rids = []
	if node is CollisionObject3D:
		rids.append(node.get_rid())
	for child in node.get_children():
		rids.append_array(_get_collision_rids(child))
	return rids


func _get_safe_basis(up: Vector3, forward_hint: Vector3) -> Basis:
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
