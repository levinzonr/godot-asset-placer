@tool
class_name AssetPlacerToolbarButton
extends Button

var _presenter: AssetPlacerPresenter


func _init() -> void:
	toggle_mode = true
	flat = true
	custom_minimum_size = Vector2(16, 16) * EditorInterface.get_editor_scale()
	var icon_image := preload("res://addons/asset_placer/icon.png").get_image()
	var icon_size := maxi(1, roundi(16.0 * EditorInterface.get_editor_scale()))
	icon_image.resize(icon_size, icon_size, Image.INTERPOLATE_LANCZOS)
	icon = ImageTexture.create_from_image(icon_image)
	tooltip_text = "Toggle Asset Placer"



func _ready() -> void:
	_presenter = AssetPlacerPresenter.instance
	set_pressed_no_signal(_presenter.plugin_is_active())
	_presenter.placer_active.connect(set_pressed_no_signal)


func _exit_tree() -> void:
	if is_instance_valid(_presenter):
		if _presenter.placer_active.is_connected(set_pressed_no_signal):
			_presenter.placer_active.disconnect(set_pressed_no_signal)
