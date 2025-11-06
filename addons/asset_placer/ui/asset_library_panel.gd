@tool
extends Control
class_name AssetLibraryPanel

@onready var asset_library_window: AssetLibraryWindow = $Panel/TabContainer/Assets
@onready var tab_container: TabContainer = $Panel/TabContainer
func _ready():
	PluginUpdater.instance.updater_update_available.connect(func(a):
		show_update_available(true)
	)
	
	PluginUpdater.instance.update_ready.connect(func(a):
		show_update_available(true)
	)
	
	PluginUpdater.instance.updater_up_to_date.connect(func():
		show_update_available(false)
	)
	AssetPlacerDockPresenter.instance.show_tab.connect(func(tab):
		tab_container.current_tab = tab
	)


func show_update_available(avaialbe: bool):
	var index = tab_container.get_tab_count() - 1
	if avaialbe:
		tab_container.set_tab_button_icon(index, EditorIconTexture2D.new("Warning"))
	else:
		tab_container.set_tab_button_icon(index, null)
