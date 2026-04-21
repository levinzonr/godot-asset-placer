@tool
extends Control

var _presenter: SettingsPresenter = SettingsPresenter.new()
@onready var reset_button: Button = %ResetButton

@onready var asset_library_button: Button = %AssetLibraryButton
@onready var reset_asset_library_button: Button = %ResetAssetLibraryButton
@onready var material_picker_button: Button = %MaterialPickerButton
@onready var material_clear_button: Button = %MaterialClearButton
@onready var plane_material_picker_button: Button = %PlaneMaterialPickerButton

@onready var trasform_step_spin_box: SpinBox = %TrasformStepSpinBox
@onready var rotation_step_spin_box: SpinBox = %RotationStepSpinBox
@onready var ui_scale_h_slider: HSlider = %UIScaleHSlider
@onready var slider_value = %SliderValue

@onready var update_channel_option_button: OptionButton = %UpdateChannelOptionButton
@onready var update_channel_info_button: Button = %UpdateChannelInfoButton

# Keybinds

@onready var kb_rotate = %KeybindingOptionRotate
@onready var kb_scale = %KeybindingOptionScale
@onready var kb_translate = %KeybindingOptionTranslate
@onready var kb_grid_snap = %KeybindingOptionGridSnap
@onready var kb_in_place_transform = %KeybindingOptionInPlaceTransform
@onready var kb_positive_transform = %KeybindingOptionPositiveTransform
@onready var kb_negative_transform = %KeybindingOptionNegativeTransform
@onready var kb_axis_x = %KeybindingOptionAxisX
@onready var kb_axis_y = %KeybindingOptionAxisY
@onready var kb_axis_z = %KeybindingOptionAxisZ
@onready var kb_plane_mode = %KeybindingOptionPlaneMode


func _ready():
	_presenter.show_settings.connect(_show_settings)
	reset_button.pressed.connect(_presenter.reset_to_defaults)

	asset_library_button.pressed.connect(_show_asset_library_picker)
	reset_asset_library_button.pressed.connect(
		_presenter.set_asset_library_path.bind(AssetPlacerSettings.DEFAULT_ASSET_LIBRARY_PATH)
	)
	material_clear_button.pressed.connect(_presenter.clear_preivew_material)
	material_picker_button.pressed.connect(_show_preview_material_picker)
	plane_material_picker_button.pressed.connect(
		func(): EditorInterface.popup_quick_open(_presenter.set_plane_material, ["BaseMaterial3D"])
	)

	ui_scale_h_slider.drag_ended.connect(
		func(changed): _presenter.set_ui_scale(ui_scale_h_slider.value)
	)
	ui_scale_h_slider.value_changed.connect(func(value): slider_value.text = str(value))
	trasform_step_spin_box.value_changed.connect(_presenter.set_default_transform_step)
	rotation_step_spin_box.value_changed.connect(_presenter.set_rotation_step)

	update_channel_option_button.item_selected.connect(_presenter.set_update_channel)
	update_channel_info_button.pressed.connect(
		func():
			OS.shell_open("https://levinzonr.github.io/godot-asset-placer/development-lifecycle/")
	)

	var bindings := AssetPlacerSettings.Bindings
	var set_binding := _presenter.set_binding

	kb_rotate.keybind_changed.connect(set_binding.bind(bindings.Rotate))
	kb_scale.keybind_changed.connect(set_binding.bind(bindings.Scale))
	kb_translate.keybind_changed.connect(set_binding.bind(bindings.Translate))
	kb_grid_snap.keybind_changed.connect(set_binding.bind(bindings.GridSnapping))

	kb_positive_transform.keybind_changed.connect(set_binding.bind(bindings.TransformPositive))
	kb_negative_transform.keybind_changed.connect(set_binding.bind(bindings.TransformNegative))
	kb_in_place_transform.keybind_changed.connect(set_binding.bind(bindings.InPlaceTransform))
	kb_axis_x.keybind_changed.connect(set_binding.bind(bindings.ToggleAxisX))
	kb_axis_y.keybind_changed.connect(set_binding.bind(bindings.ToggleAxisY))
	kb_axis_z.keybind_changed.connect(set_binding.bind(bindings.ToggleAxisZ))
	kb_plane_mode.keybind_changed.connect(set_binding.bind(bindings.TogglePlaneMode))

	_presenter.ready()


func _show_settings(setting: AssetPlacerSettings):
	asset_library_button.text = setting.asset_library_path
	asset_library_button.tooltip_text = setting.asset_library_path
	if setting.asset_library_path == setting.DEFAULT_ASSET_LIBRARY_PATH:
		reset_asset_library_button.hide()
	else:
		reset_asset_library_button.show()

	plane_material_picker_button.text = setting.plane_material_resource.get_file()
	if setting.preview_material_resource.is_empty():
		material_picker_button.text = "No Preview Material"
	else:
		material_picker_button.text = setting.preview_material_resource.get_file()

	slider_value.text = str(setting.ui_scale)
	ui_scale_h_slider.set_value_no_signal(setting.ui_scale)
	trasform_step_spin_box.set_value_no_signal(setting.transform_step)
	rotation_step_spin_box.set_value_no_signal(setting.rotation_step)

	update_channel_option_button.select(setting.update_channel)

	var bindings := AssetPlacerSettings.Bindings
	kb_rotate.set_keybind(setting.bindings[bindings.Rotate])
	kb_translate.set_keybind(setting.bindings[bindings.Translate])
	kb_scale.set_keybind(setting.bindings[bindings.Scale])
	kb_grid_snap.set_keybind(setting.bindings[bindings.GridSnapping])
	kb_in_place_transform.set_keybind(setting.bindings[bindings.InPlaceTransform])
	kb_negative_transform.set_keybind(setting.bindings[bindings.TransformNegative])
	kb_positive_transform.set_keybind(setting.bindings[bindings.TransformPositive])
	kb_axis_x.set_keybind(setting.bindings[bindings.ToggleAxisX])
	kb_axis_y.set_keybind(setting.bindings[bindings.ToggleAxisY])
	kb_axis_z.set_keybind(setting.bindings[bindings.ToggleAxisZ])
	kb_plane_mode.set_keybind(setting.bindings[bindings.TogglePlaneMode])


func _show_preview_material_picker():
	EditorInterface.popup_quick_open(_presenter.set_preview_material, ["BaseMaterial3D"])


func _show_asset_library_picker():
	var library_picker = EditorFileDialog.new()
	library_picker.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	library_picker.access = EditorFileDialog.ACCESS_RESOURCES
	library_picker.overwrite_warning_enabled = false
	library_picker.add_filter("*.json", "Asset Library")
	library_picker.file_selected.connect(_presenter.set_asset_library_path)
	EditorInterface.popup_dialog_centered(library_picker, Vector2i(720, 500))
