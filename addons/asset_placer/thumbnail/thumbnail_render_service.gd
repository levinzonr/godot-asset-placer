@tool
class_name ThumbnailRenderService
extends RefCounted

const THUMBNAIL_SIZE := Vector2i(256, 256)

static var instance: ThumbnailRenderService

var _viewport: SubViewport
var _preview_root: Node3D
var _camera: Camera3D
var _light: DirectionalLight3D


func _init():
	instance = self


func dispose():
	if is_instance_valid(_viewport):
		_viewport.queue_free()
	_viewport = null
	_preview_root = null
	_camera = null
	_light = null


func render_asset(asset: AssetResource) -> Dictionary:
	if not is_instance_valid(asset) or not asset.has_resource():
		return {"ok": false, "error": "Asset is invalid"}

	if not _ensure_viewport():
		return {"ok": false, "error": "Could not initialize renderer viewport"}

	var preview_node := _create_preview_node(asset.get_resource())
	if not is_instance_valid(preview_node):
		return {"ok": false, "error": "Asset type is not previewable"}

	_preview_root.add_child(preview_node)

	var node_aabb := AABBProvider.provide_aabb(preview_node)
	if node_aabb.size == Vector3.ZERO:
		_cleanup_preview_node(preview_node)
		return {"ok": false, "error": "Asset has no visible geometry"}

	_frame_camera(node_aabb)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var image := _viewport.get_texture().get_image()

	_cleanup_preview_node(preview_node)

	if image == null or image.is_empty():
		return {"ok": false, "error": "Renderer returned an empty image"}

	return {"ok": true, "image": image}


func _ensure_viewport() -> bool:
	if is_instance_valid(_viewport):
		return true

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return false

	_viewport = SubViewport.new()
	_viewport.name = "AssetPlacerThumbnailViewport"
	_viewport.size = THUMBNAIL_SIZE
	_viewport.transparent_bg = true
	_viewport.disable_3d = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED

	_preview_root = Node3D.new()
	_viewport.add_child(_preview_root)

	_camera = Camera3D.new()
	_camera.current = true
	_camera.near = 0.01
	_camera.far = 10000.0
	_preview_root.add_child(_camera)

	_light = DirectionalLight3D.new()
	_light.rotation_degrees = Vector3(-35.0, -30.0, 0.0)
	_preview_root.add_child(_light)

	tree.root.add_child(_viewport)
	return true


func _create_preview_node(resource: Resource) -> Node3D:
	if not is_instance_valid(resource):
		return null

	if resource is PackedScene:
		var instance_node: Node = resource.instantiate()
		if instance_node is Node3D:
			return instance_node
		instance_node.queue_free()
		return null

	if resource is Mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = resource
		return mesh_instance

	return null


func _frame_camera(bounds: AABB):
	var center: Vector3 = bounds.position + (bounds.size * 0.5)
	var radius: float = max(bounds.size.length() * 0.5, 0.25)
	var offset: Vector3 = Vector3(1.0, 0.8, 1.0).normalized() * radius * 2.8
	_camera.global_position = center + offset
	_camera.look_at(center, Vector3.UP)
	_camera.fov = 50.0
	_camera.near = max(radius / 100.0, 0.01)
	_camera.far = max(radius * 20.0, 100.0)


func _cleanup_preview_node(preview_node: Node3D):
	if not is_instance_valid(preview_node):
		return
	_preview_root.remove_child(preview_node)
	preview_node.queue_free()
