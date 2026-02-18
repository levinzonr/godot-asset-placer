@tool
class_name FolderView
extends PanelContainer

var _presenter: FolderItemPresenter

@onready var path_label: Label = %PathLabel
@onready var subfolders_checkbox: CheckBox = %SubfoldersCheckbox
@onready var delete_button: Button = %DeleteButton
@onready var sync_button: Button = %SyncButton
@onready var rules_button: Button = %RulesButton
@onready var rules_margin: MarginContainer = $VBoxContainer/RulesMargin
@onready var rules_list: VBoxContainer = %RulesList
@onready var add_rule_button: MenuButton = %AddRuleButton


func _ready():
	rules_button.pressed.connect(_toggle_rules)
	_setup_add_rule_menu()


func _setup_add_rule_menu():
	var popup = add_rule_button.get_popup()
	popup.clear()

	if popup.id_pressed.is_connected(_on_rule_type_selected):
		popup.id_pressed.disconnect(_on_rule_type_selected)

	var types = RuleFactory.get_available_types()
	for i in types.size():
		var type_id = types[i]
		var type_name = RuleFactory.get_type_name(type_id)
		popup.add_item(type_name, i)

	popup.id_pressed.connect(_on_rule_type_selected)


func _on_rule_type_selected(index: int):
	var types = RuleFactory.get_available_types()
	if index >= 0 and index < types.size():
		var type_id = types[index]
		var rule = RuleFactory.create(type_id)
		if rule:
			_presenter.add_rule(rule)
			_update_rules_button()
			_refresh_rules()


func set_folder(folder: AssetFolder):
	_presenter = FolderItemPresenter.new(folder)

	delete_button.pressed.connect(_presenter.delete)
	sync_button.pressed.connect(_presenter.sync)
	subfolders_checkbox.toggled.connect(_presenter.set_include_subfolders)

	path_label.text = folder.path
	subfolders_checkbox.button_pressed = folder.include_subfolders
	_update_rules_button()
	_refresh_rules()


func _toggle_rules():
	rules_margin.visible = not rules_margin.visible
	_update_rules_button()


func _update_rules_button():
	var rule_count = _presenter.folder.get_rule_count()
	if rule_count > 0:
		rules_button.text = "%d Rules" % rule_count
	else:
		rules_button.text = "No rules"


func _refresh_rules():
	for child in rules_list.get_children():
		child.queue_free()

	for i in _presenter.folder.rules.size():
		var rule = _presenter.folder.rules[i]
		var idx = i
		var row = rule.create_ui(_on_rule_changed, func(): _remove_rule(idx))
		rules_list.add_child(row)


func _remove_rule(index: int):
	_presenter.remove_rule_at(index)
	_update_rules_button()
	_refresh_rules()


func _on_rule_changed(rule: AssetPlacerFolderRule):
	if rule in _presenter.folder.rules:
		_presenter.save()
