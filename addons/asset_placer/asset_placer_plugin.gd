@tool
extends EditorPlugin


@onready var  _asset_placer: AssetPlacer = AssetPlacer.new()

var _asset_placer_window: AssetLibraryWindow

var plugin_path: String:
	get(): return get_script().resource_path.get_base_dir()


func _enable_plugin():
	pass
	
func _disable_plugin():
	pass
func _enter_tree():
	_asset_placer_window= load("res://addons/asset_placer/ui/asset_library_window.tscn").instantiate()
	add_control_to_bottom_panel(_asset_placer_window, "Asset Placer")
	_asset_placer_window.asset_selected.connect(func(asset):
		_asset_placer.start_placement(get_tree().root, asset)
	)

func _exit_tree():
	_asset_placer.stop_placement()
	remove_control_from_bottom_panel(_asset_placer_window)
	_asset_placer_window.queue_free()

func _handles(object):
	return true


func _forward_3d_gui_input(viewport_camera, event):
	return _asset_placer.handle_3d_input(viewport_camera, event)
