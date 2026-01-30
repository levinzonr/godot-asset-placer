@tool
class_name AddToCollectionRule
extends AssetPlacerFolderRule

var collection_id: int = -1


func get_type_id() -> String:
	return "add_to_collection"


func get_rule_name() -> String:
	return "Add to Collection"


func get_rule_description() -> String:
	var repo = AssetCollectionRepository.instance
	if repo and collection_id >= 0:
		var col = repo.find_by_id(collection_id)
		if col:
			return "Add to: " + col.name
	return "No collection selected"


func to_dict() -> Dictionary:
	var data = super.to_dict()
	data["collection_id"] = collection_id
	return data


func from_dict(data: Dictionary):
	super.from_dict(data)
	if data.has("collection_id"):
		collection_id = data["collection_id"]

func do_after_asset_added(asset: AssetResource) -> AssetResource:
	if collection_id >= 0 and not asset.tags.has(collection_id):
		asset.tags.push_back(collection_id)
	return asset

func _create_config_ui(container: Control, on_changed: Callable):
	var option_button = OptionButton.new()
	option_button.fit_to_longest_item = true

	option_button.add_item("-- Select Collection --")
	option_button.set_item_metadata(0, -1)

	var repo = AssetCollectionRepository.instance
	if repo:
		var collections = repo.get_collections()
		var selected_index = 0

		for i in collections.size():
			var collection = collections[i]
			option_button.add_item(collection.name)
			option_button.set_item_metadata(i + 1, collection.id)
			option_button.set_item_icon(i + 1, _create_color_icon(collection.background_color))

			if collection.id == collection_id:
				selected_index = i + 1

		option_button.select(selected_index)

	option_button.item_selected.connect(
		func(idx):
			collection_id = option_button.get_item_metadata(idx)
			on_changed.call(self)
	)

	container.add_child(option_button)


func _create_color_icon(color: Color) -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
