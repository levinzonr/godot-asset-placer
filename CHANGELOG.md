# Godot Asset Placer Changelog

## 1.0.0-beta4
### Added
- Updated .gitattributes to ignore files and folder that are not needed by the plugin to work #2
### Changed
- When doing an In Editor Update, the plugin will try to trigger the file scan so that the Editor is aware of the new files/changes to the existing files
### Fixed
- Fixed issue with Add Folder button not working on Onboarding screen

## 1.0.0-beta3
Added support for the Godot 4.4 and 4.3. Special thanks to @why-try313 for bringing it up, testing compatability and coming up with solutions

## 1.0.0-beta2
### Fixed
- Limit Plugin Edit to Node3D to avoid undefined behaviour

## 1.0.0-beta1
### Added
- Update collections UI to keep it consistent with picker
- Update the plugin without Restart -> Replaced with Re-Enabling the plugin
- Option to delete collections

### Fixed
- Clean up Worker Threads on Exit
- Avoid adding duplicated folders when subfolders are included 
- Fixed Grid Snapping

## 1.0.0-alpha06
### Added
- When placing assets it is now required to select a parent node where assets should placed under
By Default it will automatically select Root Node of the scene (if it is a Node3D)
- SHIFT + Mouse Click: Added to shortcut that allows to modify placed asset. This can be usefull if you want to apply additional transformations using standart editor waay


## Changed
- Moved Updater GH API calls to the background thread to avoid UI blocking

## Fixed
- Avoid adding duplicated folders
- Fixed Preview node being stuck in window when changing assets

## 1.0.0-alpha05
### Added
- Added In Editor way to update the Plugin with the latest GitHub release

## 1.0.0-alpha04
### Added

### Synchronize Process.
 During this process the plugin removes deleted assets
 from its internal memory and adds new assets that were added to the source folders.
 The process is done on the separate thread to avoid UI blocking

This is triggered by following:
- Manual Trigger (Sync Assets Button or Sync Folder button)
- When Godot completes its ReImport process
- On Plugin Startup


### Changed
- Minor UI Updates the AssetsPlacer main window
- Added asset now how more readable name when added to the tree

### Fixed
- Fixed Asset Placement when the Assst also has any CollisionObjects inside


## 1.0.0-alpha03
### Added
- Add Options To Randomly Scale placed assets
- Add more flexible options for Random Asset rotation
- Add UndoRedo Integration for asset placement
- Add Ability to Drag and Drop Folders and Assets into Assets and Folders window
### Changed
- Adjust the Icons for most fo the Icon Buttons
- Update UI for the Collection Picker

### Fixed
- Align behavior of placement to place under currently selected node3d
- Fixed and Issue of Every Mouse click resulting in Asset Placement
- Fixed and Issue of Asset flying towards the camera when in placement mode

## 1.0.0-alpha-02
### Added
- Added options for randomizing asset rotation on placement.
- Added support for grid snapping when placing assets.
- Allow for multiple collections to be selected at once for asset filtering.
- UI adjustments
- Allow asset to have multiple collections assigned to it.

## 1.0.0-alpha01
Initial release of the Godot Asset Placer plugin.
### Added
- One-click asset placement with snapping to ground and other collision shapes.
- Organize assets into collections for quick access and filtering.
- Filter assets by their name and collection.
- Basic UI for asset management and placement.
- Support for adding asset folders and reloading them.
