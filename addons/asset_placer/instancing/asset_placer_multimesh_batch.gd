@tool
class_name AssetPlacerMultiMeshBatch
extends MultiMeshInstance3D

const RENDER_PROPERTIES = [
	&"material_override",
	&"material_overlay",
	&"layers",
	&"cast_shadow",
	&"gi_mode",
	&"extra_cull_margin",
	&"lod_bias",
	&"transparency",
	&"visibility_range_begin",
	&"visibility_range_end",
	&"visibility_range_begin_margin",
	&"visibility_range_end_margin",
	&"visibility_range_fade_mode",
	&"ignore_occlusion_culling",
	&"sorting_offset",
	&"sorting_use_aabb_center",
]

@export_storage var source_asset_id: String
@export_storage var source_mesh_path: NodePath
@export_storage var source_mesh: Mesh
@export_storage var source_surface_materials: Array[Material] = []


func configure(asset_id: String, mesh_path: NodePath, source: MeshInstance3D) -> void:
	source_asset_id = asset_id
	source_mesh_path = mesh_path
	source_mesh = source.mesh
	source_surface_materials = _get_surface_materials(source)

	var batch_mesh := source_mesh
	if source_surface_materials.any(func(material): return material != null):
		batch_mesh = source_mesh.duplicate()
		for i in range(source_surface_materials.size()):
			if source_surface_materials[i] != null:
				if batch_mesh is PrimitiveMesh:
					batch_mesh.material = source_surface_materials[i]
				else:
					batch_mesh.surface_set_material(i, source_surface_materials[i])

	multimesh = MultiMesh.new()
	multimesh.resource_local_to_scene = true
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = batch_mesh
	for property in RENDER_PROPERTIES:
		set(property, source.get(property))


func matches_source(asset_id: String, mesh_path: NodePath, source: MeshInstance3D) -> bool:
	if source_asset_id != asset_id or source_mesh_path != mesh_path:
		return false
	if multimesh == null or source_mesh != source.mesh or multimesh.mesh == null:
		return false
	if source_surface_materials != _get_surface_materials(source):
		return false
	for property in RENDER_PROPERTIES:
		if get(property) != source.get(property):
			return false
	return true


func get_instance_transforms() -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	if multimesh != null:
		for i in range(multimesh.instance_count):
			transforms.append(multimesh.get_instance_transform(i))
	return transforms


func set_instance_transforms(transforms: Array[Transform3D]) -> void:
	# Rebuild private storage so resizing cannot lose old transforms or mutate a shared resource.
	var updated := MultiMesh.new()
	updated.resource_local_to_scene = true
	updated.transform_format = MultiMesh.TRANSFORM_3D
	updated.mesh = multimesh.mesh
	updated.instance_count = transforms.size()
	var bounds := AABB()
	var mesh_bounds := updated.mesh.get_aabb()
	for i in range(transforms.size()):
		updated.set_instance_transform(i, transforms[i])
		var instance_bounds := transforms[i] * mesh_bounds
		bounds = instance_bounds if i == 0 else bounds.merge(instance_bounds)
	updated.custom_aabb = bounds
	multimesh = updated


func truncate_instances(count: int) -> void:
	# A stroke can append to this batch more than once. Undo methods may run in forward
	# order, so a later undo must never grow a batch already truncated by an earlier one.
	var transforms := get_instance_transforms()
	transforms.resize(mini(count, transforms.size()))
	set_instance_transforms(transforms)


func _get_surface_materials(source: MeshInstance3D) -> Array[Material]:
	var materials: Array[Material] = []
	for i in range(source.mesh.get_surface_count()):
		materials.append(source.get_surface_override_material(i))
	return materials
