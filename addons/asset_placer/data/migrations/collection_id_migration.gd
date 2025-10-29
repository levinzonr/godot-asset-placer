extends RefCounted

var id_generator: AssetPlacerIdGenerator

func _init():
	id_generator = AssetPlacerIdGenerator.new()


func run():
	# Read the raw JSON data directly
	var file_path = "user://asset_library.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null || file.get_as_text().is_empty():
		return
	
	var json_text = file.get_as_text()
	file.close()
	

	var data: Dictionary = JSON.parse_string(json_text)
	if data == null:
		push_error("Failed to parse JSON data")
		return
	
	if data.has("version") and data["version"] == 2:
		return

	# Create backup copy before migration
	var backup_path := "user://asset_library_backup_v1.json"
	var backup_file = FileAccess.open(backup_path, FileAccess.WRITE)
	if backup_file != null:
		backup_file.store_string(json_text)
		backup_file.close()
		
	# Create mapping from collection names to IDs
	var collection_name_to_id = {}
	
	# Process collections to add IDs
	var collections_dict = data["collections"]
	for collection_dict in collections_dict:
		var id := id_generator.next_int()
		collection_dict["id"] = id
		collection_name_to_id[collection_dict["name"]] = id
	
	# Process assets to convert collection names to IDs in tags
	var assets_dict = data["assets"]
	for asset_dict in assets_dict:
		if asset_dict.has("tags"):
			var updated_tags :Array[int] = []
			for tag in asset_dict["tags"]:
				if collection_name_to_id.has(tag):
					updated_tags.append(collection_name_to_id[tag])
				else:
					pass
			asset_dict["tags"] = updated_tags
	
	# Write the updated JSON back to file
	data["version"] = 2
	var updated_json = JSON.stringify(data)
	var write_file = FileAccess.open(file_path, FileAccess.WRITE)
	write_file.store_string(updated_json)
	write_file.close()
	
	print("Collection ID migration completed successfully!")
	print("Migrated %d collections and %d assets" % [collections_dict.size(), assets_dict.size()])
	print("Collections now have IDs and are referenced by ID in asset tags")
