@tool
extends Control

@onready var new_pallete: Button = %NewPallete
@onready var palletes_container: VBoxContainer = %PalletesContainer
@onready var presenter: AssetPalletesPresenter = AssetPalletesPresenter.new()


func _ready() -> void:
	presenter.pallete_changed.connect(_show_palletes)
	new_pallete.pressed.connect(presenter.create_new_pallete)
	presenter.ready()


func _show_palletes(pallete: AssetPalette):
	for child in palletes_container.get_children():
		child.queue_free()
	for index in range(pallete.get_palette_count()):
		var pallete_instance = AssetPalleteContainer.create_pallete_container(index)
		pallete_instance.on_delete_pallete_click.connect(presenter.remove_pallete.bind(index))
		palletes_container.add_child(pallete_instance)
