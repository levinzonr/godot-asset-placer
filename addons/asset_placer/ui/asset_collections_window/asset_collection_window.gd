@tool
extends Control


@onready var chips_container: Container = %ChipsContainer
@onready var presenter := AssetCollectionsPresenter.new()
@onready var name_text_field: LineEdit = %NameTextField
@onready var color_picker_button: ColorPickerButton= %ColorPickerButton
@onready var add_button: Button = %AddButton


func _ready():
	presenter.enable_create_button.connect(func(enabled):
		add_button.disabled = !enabled
	)
	presenter.set_color(color_picker_button.color)
	presenter.clear_text_field.connect(name_text_field.clear)
	presenter.show_collections.connect(show_collections)
	presenter.ready()
	
	add_button.pressed.connect(presenter.create_collection)
	name_text_field.text_changed.connect(presenter.set_name)
	color_picker_button.color_changed.connect(presenter.set_color)


func show_collections(items: Array[AssetCollection]):
	for child in chips_container.get_children():
		child.queue_free()
	
	for item in items:
		var chip = Chip.new()
		chip.text = item.name
		chip.backgroundColor = item.backgroundColor
		chips_container.add_child(chip)
	
