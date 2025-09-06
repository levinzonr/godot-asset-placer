# Godot Asset Placer Changelog

## 1.1.0-alpha4
### Fixed
- Fixed an Issue where Snapping would not work when placing assets (#26)

## 1.1.0-alpha3

## Added
- Q Shortcut to cycle through Placement Modes
- W (Translate shortcut) preview transform now toggles `Plane Placement Mode`. This provides a way to continiously place assets on a plane with configurable point of origin
- Empty View for the Collections Picker that can navigate to the collections tab

## Fixed
- Fixed an Issue where Scale Preview transform would get reset after moving an asset
- #11 Plugins Dock now has a minimum height to avoid UI issues when collapsing it too much

## 1.1.0-alpha2
Alpha2 introduces a new Placement feature: Placement Modes and some bug fixes.

### Normal Alignment - Slopes and Vertical Surfaces
When placing assets on sloped or vertical surfaces, the asset will now align with the surface normal, providing a more natural placement.

### Placement Modes
1.1.0-alpha2 introduces the ability to choose between different placement modes

#### Surface Collision
This is  default placement mode and it is almost indentical to the approach used in previous version. This mode requires your scene to have a Collision Objects present in your scene. The RayCast will then try and hit any collision objects creating a placement point for your collision.


#### Plane Collisions (New)
This mode does not require any collision objects to be present in your scene. Instead it uses a virtual plane that has a configurable point of origin and normal direction. The RayCast will then try and hit this virtual plane creating a placement point for your collision.

> Plane Options Configuration (Normals and Origin) are not perfect as it kind of takes away from the placement flow - Right now, you need to manually change Vector3 in UI. If anyone has a idea about how to improve this please let me know.

### Added
- Added GLTF Assets Support #15

### Fixed
- Added more sanity checks for thumbnail generation
- Preview Transforms: Flipped Negative and Positive transformation directions to be more intuitive
- Add Minimum Height for the Asset Placer Dock Panel #16
- 

## 1.1.0-alpha1
First major Alpha release after the stable 1.0.0 version 🚀.

This release introduces a new feature that allows users to transform the preview of the asset before placement, including rotation and scaling options, as well as support for `obj` files and some bug fixes.
### Preview Transformation
1.1.0 introduces the ability to modify the preview of the asset before placement. This includes options for rotation and scaling, allowing users to visualize how the asset will appear in the scene prior to placement, do quick and precise adjustment modifications.

Specific transformation mode can be enabled by pressing button while in placement mode (Asset is selected) and transformations can be applied by Mouse Wheel:
- `Mouse Wheel Up`: "Positive" transformation
- `Mouse Wheel Down`: "Negative" transformation

Following transformations are supported:
- `E` to rotate (Default axis is Y)
- `R` to scale (Uniform Scale by default, All axis at once)
- `W` to translate (Default axis is Z)

This also requires an ability to select active Axis for the transformation. This can be done by pressing following keys:
- `X` to select X axis
- `Y` to select Y axis
- `Z` to select Z axis

#### UI Updates
To support this feature a 3D View Port Overlay has been added to show the current transformation mode and active axis
![addon_viewport_controls.png](docs/addon_viewport_controls.png)
### Added
- Support for `obj` files #9

### Fixed
- Fixed issue when user is able to placed asset that was removed from the library #10
- Fixed issue with assets still being presented in the library after the folder was removed #8

## 1.0.0
First stable release of the Godot Asset Placer plugin 🚀. This version includes all the features and fixes from the beta and alpha releases, providing a robust tool for asset management and placement in Godot.

### Documentation Update
- Updated Asset Placement Instructions in the README

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
