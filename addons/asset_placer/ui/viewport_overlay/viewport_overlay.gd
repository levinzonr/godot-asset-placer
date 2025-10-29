@tool
extends Control
@onready var rotate_check_button: CheckBox = %RotateCheckButton
@onready var scale_check_button: CheckBox = %ScaleCheckButton
@onready var translate_check_button: CheckBox = %TranslateCheckButton
@onready var x_check_button: CheckButton = %XCheckButton
@onready var z_check_button: CheckButton = %ZCheckButton
@onready var y_check_button: CheckButton = %YCheckButton
@onready var placement_mode_label: Label = %PlacementModeLabel
@onready var error_label: Label = %ErrorLabel
@onready var error_container: Container = %ErrorContainer
@onready var error_timer: Timer = %ErrorTimer
@onready var snapping_switch: CheckButton = %SnappingSwitch
@onready var placement_shortcut_label: Label = %PlacementShortcutLabel

var _error_position: Vector2
var _error_hidden_position: Vector2
@onready var _settings_repository := AssetPlacerSettingsRepository.instance

func _ready():
	hide()
	_error_position = error_container.position
	show_settings(_settings_repository.get_settings())
	_settings_repository.settings_changed.connect(show_settings)
	var viewport_size = get_viewport_rect().size
	_error_hidden_position = Vector2(-viewport_size.x, _error_position.y)
	error_container.position = _error_hidden_position
	var presenter = AssetPlacerPresenter._instance
	presenter.transform_mode_changed.connect(set_mode)
	presenter.preview_transform_axis_changed.connect(set_axis)
	presenter.placer_active.connect(func(a): if a: show() else: hide())
	presenter.placement_mode_changed.connect(set_placement_mode)
	presenter.options_changed.connect(show_options)
	presenter.ready()
	presenter.show_error.connect(show_error)
	error_timer.timeout.connect(hide_error)
	set_mode(presenter.transform_mode)
	set_axis(presenter.preview_transform_axis)


func set_mode(mode: AssetPlacerPresenter.TransformMode):
	rotate_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Rotate
	scale_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Scale
	translate_check_button.button_pressed = mode == AssetPlacerPresenter.TransformMode.Move

func set_placement_mode(mode: PlacementMode):
	if mode is PlacementMode.PlanePlacement:
		placement_mode_label.text = "Plane Placement"
	if mode is PlacementMode.SurfacePlacement:
		placement_mode_label.text = "Surface Placement"
	if mode is PlacementMode.Terrain3DPlacement:
		placement_mode_label.text = "Terrain3D Placement"
		
		 
func show_error(message: String):
	var tween = create_tween()
	tween.tween_property(error_container, "position", _error_position, 0.3)
	error_label.text = message
	error_timer.start()

func hide_error():
	var tween = create_tween()
	tween.tween_property(error_container, "position", _error_hidden_position, 0.3)

func show_settings(settings: AssetPlacerSettings):
	rotate_check_button.text = "%s: To Rotate" % settings.bindings[AssetPlacerSettings.Bindings.Rotate].get_display_name()
	scale_check_button.text = "%s: To Scale" % settings.bindings[AssetPlacerSettings.Bindings.Scale].get_display_name()
	translate_check_button.text = "%s: To Translate" % settings.bindings[AssetPlacerSettings.Bindings.Translate].get_display_name()
	snapping_switch.text = "%s: Grid Snapping" % settings.bindings[AssetPlacerSettings.Bindings.GridSnapping].get_display_name()
	placement_shortcut_label.text = "(%s)" % settings.bindings[AssetPlacerSettings.Bindings.TogglePlaneMode].get_display_name()


func show_options(options: AssetPlacerOptions):
	snapping_switch.button_pressed = options.snapping_enabled	
		
func set_axis(vector: Vector3):
	x_check_button.button_pressed = vector.x == 1
	y_check_button.button_pressed = vector.y == 1
	z_check_button.button_pressed = vector.z == 1
