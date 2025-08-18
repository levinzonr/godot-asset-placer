extends RefCounted
class_name ResourceIdCompat

static func path_to_uid(path:String):
	if ResourceUID.has_method("path_to_uid"):
		return ResourceUID["path_to_uid"].call(path)
	if path.begins_with("uid://"):
		return path
	var uid = ResourceUID.id_to_text(ResourceLoader.get_resource_uid(path))
	if uid == "uid://<invalid>":
		uid = path
	return uid
