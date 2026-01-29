@tool
class_name AssetThumbnail
extends TextureRect

var last_time_modified = 0

var _resource: AssetResource


func _process(_delta):
	if not is_part_of_edited_scene() and is_instance_valid(_resource) and _resource.has_resource():
		var new_time_modified = FileAccess.get_modified_time(_resource.get_path())
		if new_time_modified != last_time_modified:
			preview_resource()


func set_resource(resource: AssetResource):
	_resource = resource
	preview_resource()


func preview_resource():
	if not is_part_of_edited_scene() and is_instance_valid(_resource) and _resource.has_resource():
		last_time_modified = FileAccess.get_modified_time(_resource.get_path())
		var previewer := EditorInterface.get_resource_previewer()
		previewer.queue_resource_preview(_resource.get_path(), self, "_on_preview_generated", null)


func _on_preview_generated(_path: String, texture: Texture2D, _thumbnail, _data):
	if is_instance_valid(texture):
		self.texture = texture
