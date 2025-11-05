# Godot Asset Placer Changelog


## 1.3.0-alpha1
### Collections Management
This release introduces `Collections Management` dialog which is accessible from the collections window. The purpose is to streamline Collections and Asset management.

The dialog provide a more intuitive and convenient way to assign and remove assets to/from the collections

![](./docs/assets/manage_collections.png)


## 1.2.1
### Fixed
- Made Asset Collections Scrollable
- Fix Icon in About Window

## 1.2.0

Version **1.2.0** is a major feature release that introduces a comprehensive Settings Panel, In Place Transform Mode, Random Asset Placement, and enhanced Placer options for more flexible asset placement workflows.

### ✨ New Features

#### ⚙️ Settings Panel ⚙️
This release introduces a dedicated Settings Panel for the Asset Placer, allowing you to customize and tweak the plugin to your needs.

**General Settings:**
- Preview Material configuration - You can disable or choose your own Material3D resource to be used as a preview material for Asset Placement
- Plane Material customization - Modify the material of the Plane used in Plane Placement Mode to better suit your scene (Project level settings)
- Transform Step configuration - Configure the amount of rotation/scale applied per Mouse Wheel step when in Preview Transform mode
  - Rotation Step Default: 5 degrees
  - Scale/Translate Step Default: 0.1 Units
- Thumbnail UI Scale option - Scales up/down the size of the items inside Assets Panel (Default: 1.0). This partially addresses issues like #28 and #38
- Asset Library .json file path configuration - Set custom location of the library data source file. This is helpful if you want this file to be version controlled and shared between all developers with access to the project. By default the path will be an internal Godot user folder. This can be changed through Project Settings -> Advanced -> Godot Asset Placer.

**Key Bindings:**
You can now customize the key bindings for various actions within the Asset Placer plugin:
- Rotate (Default: E)
- Scale (Default: R)
- Translate (Default: W)
- Cycle Placement Modes (Default: Q)
- Toggle Snapping (Default: S)
- Toggle X, Y, Z Axis (Default: X, Y, Z keys respectively)
- Transform Apply (Default: Mouse Wheel Up/Down)
- In Place Transform Mode (Default: Shift+E)

Key Bindings support Mouse Button and Modifiers Combinations (Ctrl/CMD, Shift, Alt/Options), providing more flexibility when choosing key bindings and allowing you to avoid conflicts with existing Godot shortcuts.

The conflicting key will be unassigned and highlighted in red in the Settings Panel


#### In Place Transform Mode
**In Place Transform Mode** allows users to apply transformations using Asset Placer flow to existing Nodes that are already present in the scene tree. To enter this mode, select a Node3D in the scene tree and press "Shift+E" (Default Shortcut and configurable in Settings). After that, you can use the same Preview Transform shortcuts to modify the selected Node3D.

#### Random Asset Placement
This release introduces a new checkbox in the Asset Placement Options UI that allows users to enable/disable random placement of assets. When enabled, a new asset will be selected randomly from the current filtered list of assets in the Assets Panel. This will happen after each placement.

> ⚠️ While this feature does work, we consider this feature to be experimental and might require further improvements in the future

#### New Placer Options
Two new placement alignment options have been added to the Asset Placement Options:

- **Align Normals** - When enabled, assets will align with surface normals during placement, providing more natural placement on sloped or vertical surfaces
- **Use Assets Origin** / **Scene Bottom Alignment** - Control whether assets should be placed using their local origin point (Use Assets Origin enabled) or their actual bottom (Use Assets Origin disabled). Using Asset Origin is particularly useful for assets that have a defined base or origin point that should remain "under" the surface, such as Trees

### Collections Improvements
- It is now possible to Edit Collections (Color, Name) from the Collections Tab
- Collections UI has been updated to be more consistent with the rest of the plugin
- ⚠️ **Breaking Change:** Collections are now identified by a unique ID instead of Name. The Migration is part of the plugin update and should run automatically and ideally should not cause any issues. However, if you have any issues with collections after updating please reach out. Your `asset_library.json` (https://github.com/levinzonr/godot-asset-placer/issues/44) will be backed-up automatically just in case.


---

## 1.2.0-beta2
### Fixed
- Collection Picker not showing current status of the Assigned collections

## 1.2.0-beta1
### Added
- Added a Plane Mode Toggle Configuration option
- Asset Library .json file can now be changed. This allows you set custom location of the library data source file which is helpful if you want this file to be version controlled and shared between all developers with the access to the project. By default the path will be an internal Godot user folder. This can be changed through Project Settings -> Advanced -> Godot Asset Placer.

### Fixed
- Remove unneeded logs from the Collection Migration Code, Made sure migration only runs when is needed

## 1.2.0-alpha4
### Fixed
- Fixed an Issue with when Placing Asset on a Plane in Plane Placement Mode breaks the placement flow. This was due the input handling and event being propagated to the Editor

## 1.2.0-alpha3

> ⚠️ Contains Breaking changes for the Collections System. Please read the notes below before updating.

### Collections Improvements
- It is now possible to Edit Collections (Color, Name) from the Collections Tab
- Collections UI has been updated to be more consistent with the rest of the plugin
- ⚠️ Breaking Change: Collections are now identified by a unique ID instead of Name. The Migration is part of the plugin update and should run automatically and ideally should not cause any issues.
  However, if you have any issues with collections after updating please reach out. It is recommended to backup your `asset_library.json` (https://github.com/levinzonr/godot-asset-placer/issues/44) before updating the plugin to this version.

### Random Asset Placement
This release introduces a new check box in the Asset Placement Options UI that allows users to enable/disable random placement of assets.
When enabled, new asset will be selected randomly from the current filtered list of assets in the Assets Panel. This will happen after each placement.

> While this feature does work I do consider this feature to be experimental and might require further improvements in the future

### Additions to the Settings Panel
- Added Option to configure Toggling X, Y and Z Axis (Default: X, Y, Z keys respectively)
- Added Key Binding Conflict Detection: The conflicting key will be unasigned and highlighted in red in the Settings Panel
- Added Option to configure shortcut for Transform Apply (Default: Mouse Wheel Up/Down)
- Added `Thumbnail US Scale` option. This scales up/down the size of the items inside Assets Panel (Default: 1.0). This is partially addessing issues like #28 and #38


## 1.2.0-alpha2
### Added
- **In Place Transform Mode** allows users to apply transformations using Asset Placer flow to the existing Nodes that are already present in the scene tree. To Enter this mode select a Node3D in the scene tree and press the "Shift+E" (Default Shortcut and Configurable in Settings). After that, you can use the same Preview Transform shortcuts to modify the selected Node3D.
- Added Transform Step to the Settings Panel. This allows users to configure the amount of rotation/scale applied per Mouse Wheel step when in Preview Transform mode.
  - Rotation Step Default: 5 degrees
  - Scale/Translate Step Default: 0.1 Units
- Added the ability to modify the material of the Plane used in Plane Placement Mode. This allows users to customize the appearance of the placement plane to better suit their scene and preferences. (Project level settings)

### Changed
- Key Bindings now can also allow for Mouse Button and Modifiers Combinations (Ctrl, Shift, Alt). This provides more flexibility when choosing key bindings and allows to avoid conflicts with existing Godot shortcuts.
- Preview Material is now a Project Level Setting. This allows different projects to have different preview materials without affecting each other.

## 1.2.0-alpha1
### ⚙︎ Settings Panel ⚙︎
This Release introduces a dedicated Settings Panel for the Asset Placer. This allows you to further more customize your experience and tweak the plugin to your needs

#### General Settings
Previously hardcoded settings are now exposed in the Settings Panel:
- Preview Material (#43) - You can disable, or choose your own Material3D resource to be used as a preview material for Asset Placement

#### Key Bindings
You can now customize the key bindings for various actions within the Asset Placer plugin. This includes
- Rotate (Default: E)
- Scale (Default: R)
- Translate (Default: W)
- Cycle Placement Modes (Default: Q)
- Toggle Snapping (Default: S)

All The changes made will be persisted across Godot sessions within EditorSettings, and as such, across all your Projects


## 1.1.8
### Added
Added support of Using Asset Origin for Placement (Addressing issue #42)
With this feature enabled, the asset will be placed with its local origin point aligned to the placement surface,
rather than using Assets Actual bottom. This is particularly useful for assets that have a defined base or origin point that should remain "under" the surface, such as Trees

## 1.1.7
### Added
- Added AlignNormals checkbox to AssetPlacement options (#40). The checkbox is enabled by default and can be changed via Asset Placement Options UI
  - Provides users with control over whether assets should align with surface normals during placement
  - Enhances flexibility for different placement scenarios

### Fixed
- Fixed rotation transforms to use degrees instead of radians (#41) by @Mewlkor
  - Improves user experience by using more intuitive degree values for rotation
  - Ensures consistency with Godot's rotation system

## 1.1.6
### Fixed
- Fixed an Issue when Placed Asset rotation would not correspond to the Preview Node rotation. Was happening when Root Node had non-default rotation transform
### Changed
- Another small update to the "Update Flow". The Update now is split into 2 steps instead of one: Download and Apply. Goal is to make it more consistent

## 1.1.5
### Changed
chore: Tweak export-ignore configuration to exclude top-level LICENSE and dotfiles (#36) by @akien-mga

	The LICENSE is already included in `addons/asset_placer/` to ship in user
	projects. The top-level one could conflict with user projects, or appear
	to define their license terms.
	
	Ensure we don't export dotfiles like `.gitignore` or `.gitattributes`
	in archives either, and remove stray `.DS_Store` files.
	
	Remove usage of top-level `icon.svg` as placeholder in the plugin, replace it
	by in-plugin icon.png with the same size (128x128).

## 1.1.4
### Fixed
- Moved the icon outside of the root package (#35)

## 1.1.3
### Fixed
- Fixed an Icon not being exported for the ViewPortOverlay

## 1.1.2
### Fixed
- Fixed an Issue when Asset Placer would react to Inputs inside 3D Viewport while plugin is inactive (asset is not selected)

## 1.1.1
### Fixed
- Fixed and Issue when Asset Placer still remains active after dock panel is closed/changed (#31)
- Fixed an Issue with Asset Placer shortcuts interfering with Existing Godot shortcuts #27. 
- terrain_3d addon used for demo purposes is now removed from the plugin when exporting as zip
- Decrease min height of dock panel window

### Changed
- Bring back Editor Restart when updating the plugin. Disabling and Enabling the plugin does not fully reload all the resources and may lead to unexpected behaviour

## 1.1.0

Version **1.1.0** is a major feature update that introduces new placement modes, preview transformations, and various improvements and fixes to enhance the asset placement experience in Godot.

### ✨ New Features
1.1.0 Introduce Placement Modes and Preview Transformations that allow for more flexible and intuitive asset placement in 3D scenes.

#### Placement Modes
A new system for controlling how assets are placed in your scene:
- **Surface Collision** – Default placement mode, using collision objects in the scene (same as before).
- **Plane Collision** – Place assets on a configurable infinite plane without needing collision objects.
	- Plane can now detect collisions from both sides.
	- Plane preview material is now **unshaded** for consistent visibility across environments.
- **Terrain3D Placement** – Dedicated support for [Terrain3D plugin](https://github.com/TokisanGames/Terrain3D), ensuring assets align properly with terrain surfaces.

#### Preview Transformations
You can now adjust asset transforms before placement:
- **Rotate (`E`)** – Default rotation axis is Y.
- **Scale (`R`)** – Uniform scaling by default.
- **Translate (`W`)** – Tied to Plane Placement Mode for continuous placement.
- **Axis Selection** – Switch between X, Y, Z with hotkeys.
- Mouse Wheel applies transformations ("positive" / "negative" values).
- A **viewport overlay** displays the current mode and active axis.

#### Random Transformations
Random Transformations are now mutually exclusive with Manual Preview Transformations to avoid conflicts.
This means if you enable manual transformations, random transformations will be disabled automatically and vice versa.


#### Shortcuts & UI Improvements
- `Q` – Cycle through placement modes.
- `W` – Translate Mode now works with Plane Placement Mode.
- `S` – Toggle snapping on/off.
- Viewport overlay updated for better readability on all backgrounds.
- Added **snapping state indicator** in the overlay.
- Added **empty view** for collection picker with navigation shortcut.
---
### 🛠️ Fixes & Improvements
- Assets now properly align with **slopes and vertical surfaces** using surface normals.
- Fixed snapping not working correctly during placement.
- Fixed scale preview resetting after moving an asset.
- Dock panel now has a **minimum height** to prevent UI collapse issues.
- Improved thumbnail generation with additional checks.
- Transformation directions flipped for more intuitive behavior.
- Numerous UI polish updates across overlays, pickers, and collections.
---
### 📂 Format Support
- Added support for **GLTF** assets.
- Added support for **OBJ** assets.
---

### 1.1.0-beta1
With this release I believe new features are more or less stable and no more major changes expected, other than bug fixes
### Changed
- Error toast from ViewPort overlay is now a bit smaller and positioned lower so it is less intrusive
- `W` Translate Mode is now fully relies on Plane Placement Mode. Activating Translate Mode Activates Plane Placement Mode. This provides a way to continiously place assets on a plane with configurable point of origin. Translate Mode now translates that plane instead of asset itself
- Plane in PlanePlacementMode now can detect collisions from both sides
- Update ViewPort Overlay UI to be more readable on different backgrounds
- Made Plane Preview Material Unshaded so it consistent across environments 

### 1.1.0-alpha5
### Terrain 3D Placement Mode
Another addition to the Placement Modes is the Terrain 3D Placement Mode. This mode is specifically designed to work with [Terrain3D Plugin](https://github.com/TokisanGames/Terrain3D), allowing for accurate placement of assets on terrain surfaces.

Terrain3D Placement mode requires users to choose Terrain3D Node when activated. After that node is selected, Placement should work as usual

### Added
- Added Shortcut `S` to toggle Snapping On/Off
- Added UI Indicator for Snapping State to the Viewport Overlay

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
