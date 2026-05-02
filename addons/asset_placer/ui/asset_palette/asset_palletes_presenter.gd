extends RefCounted
class_name AssetPalletesPresenter

signal pallete_changed(pallete: AssetPalette)



func ready() -> void:
	var pallete := APEditorSettingsManager.get_editor_settings().get_asset_palette()
	pallete_changed.emit(pallete)
	pallete.palette_changed.connect(func(): pallete_changed.emit(pallete))

func create_new_pallete() -> void:
	var pallete = APEditorSettingsManager.get_editor_settings().get_asset_palette()
	pallete.add_new_palette()



func remove_pallete(palette_index: int) -> void:
	var pallete = APEditorSettingsManager.get_editor_settings().get_asset_palette()
	pallete.remove_palette(palette_index)
