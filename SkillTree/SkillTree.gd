extends Control

@onready var data: PlayerData = GameManager.player_data

var upgrades: Dictionary[StringName, SkillUpgrade] = {}
var hovered: SkillUpgrade
var hovered_button: Button


func _ready() -> void:
	%Menu.pressed.connect(Interface.toggle_pause)
	%NextRun.pressed.connect(SignalBus.round_start.emit)
	%NextRun.focus_entered.connect(_hide_details)
	%Results.text = "+%d" % GameManager.last_run_earnings
	for upgrade: SkillUpgrade in PlayerData.UPGRADES.upgrades:
		upgrades[upgrade.id] = upgrade
		var button: Button = %Tree.get_node(NodePath(upgrade.id))
		button.pressed.connect(data.unlock.bind(upgrade))
		button.gui_input.connect(_on_upgrade_input.bind(upgrade, button))
		button.mouse_exited.connect(_hide_details)
		button.focus_entered.connect(_show_details.bind(upgrade, button))
	data.changed.connect(_refresh)
	_refresh()
	%TreeViewport.view_changed.connect(_hide_details)
	%NextRun.grab_focus()


func _refresh() -> void:
	%Money.text = str(data.money)
	for upgrade: SkillUpgrade in PlayerData.UPGRADES.upgrades:
		var button: UpgradeNode = %Tree.get_node(NodePath(upgrade.id))
		button.refresh(upgrade, data)
		var link: Line2D = %Tree.get_node("Links/" + upgrade.id)
		link.default_color = button.get_theme_color(&"link_color")
		link.antialiased = true
	if hovered:
		_show_details(hovered, hovered_button)


func _on_upgrade_input(event: InputEvent, upgrade: SkillUpgrade, button: Button) -> void:
	if event is InputEventMouseMotion:
		_show_details(upgrade, button)


func _show_details(upgrade: SkillUpgrade, button: Button) -> void:
	if %TreeViewport.panning:
		return
	hovered = upgrade
	hovered_button = button
	%Effect.text = upgrade.effect
	%Cost.text = "Unlocked" if data.unlocked.has(upgrade.id) else "$%d" % upgrade.cost
	%Requires.visible = not upgrade.prerequisite.is_empty() and not data.unlocked.has(upgrade.prerequisite)
	if %Requires.visible:
		%Requires.text = "Requires: " + upgrades[upgrade.prerequisite].effect
	%Details.size = %Details.get_combined_minimum_size()
	var center := button.get_global_rect().get_center()
	var desired := center - Vector2(%Details.size.x / 2.0, %Details.size.y + 40.0)
	%Details.position = desired.clamp(Vector2(8, 8), size - %Details.size - Vector2(8, 8))
	%Details.show()


func _hide_details() -> void:
	hovered = null
	hovered_button = null
	%Details.hide()
