extends RefCounted
class_name AABBProvider

static func provide_aabb(node: Node3D) -> AABB:
	return _get_combined_aabb(node)
	
	
static func _get_combined_aabb(root: Node3D) -> AABB:
	var aabb := AABB()
	var first = true

	# Include root if it is a MeshInstance3D
	if root is MeshInstance3D:
		var mesh: Mesh = root.mesh
		if mesh:
			var local_aabb: AABB = mesh.get_aabb()
			# Use transform instead of global_transform
			local_aabb = _transform_aabb(local_aabb, root.global_transform)
			aabb = local_aabb
			first = false

	for child in root.get_children():
		if child is Node3D:
			var sub_aabb = _get_combined_aabb(child)
			if !first:
				aabb = aabb.merge(sub_aabb)
			else:
				aabb = sub_aabb
				first = false

	return aabb

static func _transform_aabb(aabb: AABB, transform: Transform3D) -> AABB:
	var corners = [
		Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z),
		Vector3(aabb.position.x, aabb.position.y, aabb.position.z + aabb.size.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z + aabb.size.z),
		Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb.size.z),
		Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb.size.z)
	]

	var transformed = transform * corners[0]
	var result = AABB(transformed, Vector3.ZERO)

	for i in range(1, corners.size()):
		transformed = transform * corners[i]
		result = result.expand(transformed)

	return result
