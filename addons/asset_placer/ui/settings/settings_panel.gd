@tool
extends Control

var _presenter: SettingsPresenter = SettingsPresenter.new()
@onready var reset_button: Button = %ResetButton

@onready var asset_library_button: Button = %AssetLibraryButton
@onready var material_picker_button: Button = %MaterialPickerButton
@onready var material_clear_button: Button = %MaterialClearButton
@onready var plane_material_picker_button: Button = %PlaneMaterialPickerButton

@onready var trasform_step_spin_box: SpinBox = %TrasformStepSpinBox
@onready var rotation_step_spin_box: SpinBox = %RotationStepSpinBox
@onready var ui_scale_h_slider: HSlider = %UIScaleHSlider
@onready var slider_value = %SliderValue

@onready var update_channel_option_button: OptionButton = %UpdateChannelOptionButton
@onready var update_channel_info_button: Button = %UpdateChannelInfoButton

@onready var keybinding_option_rotate = %KeybindingOptionRotate
@onready var keybinding_option_scale = %KeybindingOptionScale
@onready var keybinding_option_translate = %KeybindingOptionTranslate
@onready var keybinding_option_grid_snap = %KeybindingOptionGridSnap
@onready var keybinding_option_in_place_transform = %KeybindingOptionInPlaceTransform
@onready var keybinding_option_positive_transform = %KeybindingOptionPositiveTransform
@onready var keybinding_option_negative_transform = %KeybindingOptionNegativeTransform
@onready var keybinding_option_axis_x = %KeybindingOptionAxisX
@onready var keybinding_option_axis_y = %KeybindingOptionAxisY
@onready var keybinding_option_axis_z = %KeybindingOptionAxisZ
@onready var keybinding_option_plane_mode = %KeybindingOptionPlaneMode


func _ready():
	_presenter.show_settings.connect(_show_settings)
	reset_button.pressed.connect(_presenter.reset_to_defaults)

	asset_library_button.pressed.connect(_show_asset_library_picker)
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

	keybinding_option_rotate.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.Rotate, key)
	)

	keybinding_option_positive_transform.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.TransformPositive, key)
	)

	keybinding_option_translate.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.Translate, key)
	)

	keybinding_option_plane_mode.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.TogglePlaneMode, key)
	)

	keybinding_option_negative_transform.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.TransformNegative, key)
	)
	keybinding_option_scale.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.Scale, key)
	)
	keybinding_option_in_place_transform.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.InPlaceTransform, key)
	)
	keybinding_option_grid_snap.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.GridSnapping, key)
	)
	keybinding_option_axis_x.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.ToggleAxisX, key)
	)
	keybinding_option_axis_y.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.ToggleAxisY, key)
	)
	keybinding_option_axis_z.keybind_changed.connect(
		func(key): _presenter.set_binding(AssetPlacerSettings.Bindings.ToggleAxisZ, key)
	)

	_presenter.ready()


func _show_settings(setting: AssetPlacerSettings):
	asset_library_button.text = setting.asset_library_path
	asset_library_button.tooltip_text = setting.asset_library_path

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

	var Bindings := AssetPlacerSettings.Bindings
	var bindings := setting.bindings
	keybinding_option_rotate.set_keybind(bindings[AssetPlacerSettings.Bindings.Rotate])
	keybinding_option_translate.set_keybind(bindings[Bindings.Translate])
	keybinding_option_scale.set_keybind(bindings[Bindings.Scale])
	keybinding_option_grid_snap.set_keybind(bindings[Bindings.GridSnapping])
	keybinding_option_in_place_transform.set_keybind(bindings[Bindings.InPlaceTransform])
	keybinding_option_negative_transform.set_keybind(bindings[Bindings.TransformNegative])
	keybinding_option_positive_transform.set_keybind(bindings[Bindings.TransformPositive])
	keybinding_option_axis_x.set_keybind(bindings[Bindings.ToggleAxisX])
	keybinding_option_axis_y.set_keybind(bindings[Bindings.ToggleAxisY])
	keybinding_option_axis_z.set_keybind(bindings[Bindings.ToggleAxisZ])
	keybinding_option_plane_mode.set_keybind(bindings[Bindings.TogglePlaneMode])


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
