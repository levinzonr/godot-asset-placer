class_name InstancingStrategy
extends RefCounted

var _undo_redo: EditorUndoRedoManager


## Must be called before placing instances.
func setup(undo_redo: EditorUndoRedoManager) -> void:
	_undo_redo = undo_redo


## Applies finalized world transforms and records changes in the caller's open undo action.
## Changes must be applied immediately; the caller commits with commit_action(false).
## Implementations must record deterministic redo operations rather than regenerate transforms.
func place_instances(
	_asset: AssetResource,
	_world_transforms: Array[Transform3D],
	_parent: Node3D
) -> void:
	push_error("InstancingStrategy.place_instances() must be implemented")
