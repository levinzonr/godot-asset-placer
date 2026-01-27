class_name AssetPlacerDockPresenter
extends RefCounted

signal show_tab(tab: Tab)

enum Tab { Assets, Folders, Collections, About }

static var instance: AssetPlacerDockPresenter


func _init():
	instance = self
