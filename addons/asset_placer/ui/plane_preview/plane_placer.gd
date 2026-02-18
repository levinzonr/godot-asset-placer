class_name PlanePlacer
extends RefCounted

var presenter: AssetPlacerPresenter

var _current_plane_options = PlaneOptions.new(Vector3.UP, Vector3.ZERO)
var _new_plane_options: PlaneOptions = PlaneOptions.new(Vector3.UP, Vector3.ZERO)
var _last_mouse_position: Vector2


func _init(presenter: AssetPlacerPresenter, _plane: Node3D):
	self.presenter = presenter
	presenter.placement_mode_changed.connect(
		func(mode: GapPlacementMode):
			if mode is GapPlacementMode.PlanePlacement:
				_new_plane_options = mode.plane_options
	)


func move_plane_up(value: float):
	_new_plane_options.origin += _new_plane_options.normal * value
	presenter.placement_mode = GapPlacementMode.PlanePlacement.new(_new_plane_options)
