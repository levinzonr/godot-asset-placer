@tool
extends Control

var _presenter: SettingsPresenter = SettingsPresenter.new()
@onready var keybinding_option_rotate = %KeybindingOptionRotate
@onready var keybinding_option_scale = %KeybindingOptionScale
@onready var keybinding_option_translate = %KeybindingOptionTranslate
@onready var keybinding_option_grid_snap = %KeybindingOptionGridSnap
@onready var reset_button: Button = %ResetButton

@onready var material_picker_button = %MaterialPickerButton
@onready var material_clear_button = %MaterialClearButton
@onready var plane_material_picker_button: Button = %PlaneMaterialPickerButton
@onready var keybinding_option_in_place_transform = %KeybindingOptionInPlaceTransform
@onready var trasform_step_spin_box: SpinBox = %TrasformStepSpinBox
@onready var rotation_step_spin_box: SpinBox = %RotationStepSpinBox
@onready var ui_scale_h_slider: HSlider = %UIScaleHSlider
@onready var slider_value = %SliderValue
@onready var keybinding_option_positive_transform = %KeybindingOptionPositiveTransform
@onready var keybinding_option_negative_transform = %KeybindingOptionNegativeTransform
@onready var keybinding_option_axis_x = %KeybindingOptionAxisX
@onready var keybinding_option_axis_y = %KeybindingOptionAxisY
@onready var keybinding_option_axis_z = %KeybindingOptionAxisZ
@onready var keybinding_option_plane_mode = $Panel/MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/KeyBindings/KeyBindingsOptions/KeybindingOptionPlaneMode
@onready var update_channel_option_button: OptionButton = %UpdateChannelOptionButton
@onready var update_channel_info_button: Button = %UpdateChannelInfoButton


func _ready():
	ui_scale_h_slider.drag_ended.connect(func(changed):
		_presenter.set_ui_scale(ui_scale_h_slider.value)
	)
	ui_scale_h_slider.value_changed.connect(func(value):
		slider_value.text = str(value)
	)
	trasform_step_spin_box.value_changed.connect(_presenter.set_default_transform_step)
	rotation_step_spin_box.value_changed.connect(_presenter.set_rotation_step)
	_presenter.show_settings.connect(_show_settings)
	update_channel_option_button.item_selected.connect(_presenter.set_update_channel)
	keybinding_option_rotate.keybind_changed.connect(func(key):
		_presenter.set_binding(AssetPlacerSettings.Bindings.Rotate, key)
	)
	
	keybinding_option_positive_transform.keybind_changed.connect(func(key):
		_presenter.set_binding(AssetPlacerSettings.Bindings.TransformPositive, key)
	)
	
	keybinding_option_translate.keybind_changed.connect(func(key): 
		_presenter.set_binding(AssetPlacerSettings.Bindings.Translate, key)
	)
	
	keybinding_option_plane_mode.keybind_changed.connect(func(key): 
		_presenter.set_binding(AssetPlacerSettings.Bindings.TogglePlaneMode, key)
	)
	
	keybinding_option_negative_transform.keybind_changed.connect(func(key): 
		_presenter.set_binding(AssetPlacerSettings.Bindings.TransformNegative, key)
	)
	keybinding_option_scale.keybind_changed.connect(func(key):
		_presenter.set_binding(AssetPlacerSettings.Bindings.Scale, key)
	)
	keybinding_option_in_place_transform.keybind_changed.connect(func(key):
		_presenter.set_binding(AssetPlacerSettings.Bindings.InPlaceTransform, key)
	)
	keybinding_option_grid_snap.keybind_changed.connect(func(key): 
		_presenter.set_binding(AssetPlacerSettings.Bindings.GridSnapping, key)
	)
	keybinding_option_axis_x.keybind_changed.connect(func(key):
		_presenter.set_binding(AssetPlacerSettings.Bindings.ToggleAxisX, key)
	)
	keybinding_option_axis_y.keybind_changed.connect(func(key):
		_presenter.set_binding(AssetPlacerSettings.Bindings.ToggleAxisY, key)
	)
	keybinding_option_axis_z.keybind_changed.connect(func(key):
		_presenter.set_binding(AssetPlacerSettings.Bindings.ToggleAxisZ, key)
	)
	reset_button.pressed.connect(_presenter.reset_to_defaults)
	material_clear_button.pressed.connect(_presenter.clear_preivew_material)
	material_picker_button.pressed.connect(_show_preview_material_picker)
	
	update_channel_info_button.pressed.connect(func():
		OS.shell_open("https://levinzonr.github.io/godot-asset-placer/development-lifecycle/")
	)
	
	plane_material_picker_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_presenter.set_plane_material, ["BaseMaterial3D"])
	)
	_presenter.ready()

func _show_settings(setting: AssetPlacerSettings):
	slider_value.text = str(setting.ui_scale)
	ui_scale_h_slider.set_value_no_signal(setting.ui_scale)
	trasform_step_spin_box.set_value_no_signal(setting.transform_step)
	rotation_step_spin_box.set_value_no_signal(setting.rotation_step)
	keybinding_option_rotate.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.Rotate])
	keybinding_option_translate.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.Translate])
	keybinding_option_scale.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.Scale])
	keybinding_option_grid_snap.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.GridSnapping])
	keybinding_option_in_place_transform.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.InPlaceTransform])
	keybinding_option_negative_transform.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.TransformNegative])
	keybinding_option_positive_transform.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.TransformPositive])
	keybinding_option_axis_x.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.ToggleAxisX])
	keybinding_option_axis_y.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.ToggleAxisY])
	keybinding_option_axis_z.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.ToggleAxisZ])
	keybinding_option_plane_mode.set_keybind(setting.bindings[AssetPlacerSettings.Bindings.TogglePlaneMode])
	update_channel_option_button.select(setting.update_channel)
	plane_material_picker_button.text = setting.plane_material_resource.get_file()
	if setting.preview_material_resource.is_empty():
		material_picker_button.text = "No Preview Material"
	else:
		material_picker_button.text = setting.preview_material_resource.get_file()
	

func _show_preview_material_picker():
	EditorInterface.popup_quick_open(_presenter.set_preview_material, ["BaseMaterial3D"])
