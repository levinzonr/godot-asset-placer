# Godot Asset Placer
This is Godot Editor plugin that allows for quick asset placement and management when working with large 3D Scenes.

> This plugin is still in development and may have bugs or incomplete features. Please report any issues you encounter
>
> Any Features and Suggestions are welcome as well

# Features
- One-Click Asset Placement with Snapping to Ground and other Collision shapes
- Organize Assets into collections for quick access and filtering
- Filter Assets by their name and collection
- Grid snapping when placing assets
- Randomize asset Rotation and Scale on placement
- Undo-Redo Integration
- Internal library is Synchronized with File System
- In Editor Update when new release is published on GitHub

<p align="center">
  <a href="https://youtu.be/ffRDdsYeiqM" target="_blank">
	<img src="https://img.youtube.com/vi/ffRDdsYeiqM/0.jpg" alt="YouTube Video" />
  </a>
</p>

![addon_preview.png](docs/addon_preview.png)

# Installation
1. Clone the repository
2. Copy the `addons/asset_placer` folder into your Godot project under the `addons` directory.
3. Enable the plugin in the Godot Editor by going to `Project` -> `Project Settings` -> `Plugins` and enabling the `Asset Placer` plugin.

# Usage
## Adding Assets
Right now the plugin relies on user selecting the folders where your assets are located so that not every scene is added automatically.
You can folders to sync by either Drag And Droping the folder or  using "Add folder button" within Folders Tab
![addon_folders.png](docs/addon_folders.png)


## Placing Assets
To place an asset, select it from the list and click and navigate to the 3D scene of you choice. If all goes well, you should see a preview of your asset snapping to the neares surface
Click again to place the asset in the scene.

## Organizing Assets
You can organize your assets into collections by selecting the assets and clicking the "Create Collection" button. This will create a new collection with the selected assets. You can also filter assets by their name and collection using the search bar at the top of the plugin window.

Collections is a simple way to "group" assets together by some criteria. For example, you can create a collection for all the trees in your scene, or all the rocks, etc.

## Known Issues
- So far plugin only supports .tscn files, glb and fbx models. If you have any other formats you would like to see supported, please let me know.
- The UI is work in progress..


## Contributing
Found a problem or have an idea?
- [🐛 Report a bug](https://github.com/levinzonr/godot-asset-placer/issues/new?template=bug_report.md&labels=bug&title=%5BBUG%5D%20)
- [✨ Request a feature](https://github.com/levinzonr/godot-asset-placer/issues/new?template=feature_request.md&labels=enhancement&title=%5BFeature%5D%20)


## Changelog
See the [CHANGELOG.md](CHANGELOG.md) for a full list of changes and updates.
