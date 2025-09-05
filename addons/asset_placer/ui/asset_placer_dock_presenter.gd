extends RefCounted
class_name AssetPlacerDockPresenter

enum Tab {
	Assets, Folders, Collections, About
}


signal show_tab(tab: Tab)

func _init():
	instance = self

static var instance: AssetPlacerDockPresenter
