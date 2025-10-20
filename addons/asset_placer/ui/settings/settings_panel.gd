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


func _ready():
	_presenter.show_settings.connect(_show_settings)
	keybinding_option_rotate.keybind_changed.connect(_presenter.set_rotate_binding)
	keybinding_option_translate.keybind_changed.connect(_presenter.set_translate_binding)
	keybinding_option_scale.keybind_changed.connect(_presenter.set_scale_binding)
	keybinding_option_grid_snap.keybind_changed.connect(_presenter.set_grid_snap_binding)
	reset_button.pressed.connect(_presenter.reset_to_defaults)
	material_clear_button.pressed.connect(_presenter.clear_preivew_material)
	material_picker_button.pressed.connect(_show_preview_material_picker)
	plane_material_picker_button.pressed.connect(func():
		EditorInterface.popup_quick_open(_presenter.set_plane_material, ["BaseMaterial3D"])
	)
	_presenter.ready()

func _show_settings(setting: AssetPlacerSettings):
	keybinding_option_rotate.set_keybind(setting.binding_rotate)
	keybinding_option_translate.set_keybind(setting.binding_translate)
	keybinding_option_scale.set_keybind(setting.binding_scale)
	keybinding_option_grid_snap.set_keybind(setting.binding_grid_snap)
	plane_material_picker_button.text = setting.plane_material_resource.get_file()
	if setting.preview_material_resource.is_empty():
		material_picker_button.text = "No Preview Material"
	else:
		material_picker_button.text = setting.preview_material_resource.get_file()
	

func _show_preview_material_picker():
	EditorInterface.popup_quick_open(_presenter.set_preview_material, ["BaseMaterial3D"])
