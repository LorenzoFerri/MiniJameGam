class_name UpgradeNode
extends Button

func refresh(upgrade: SkillUpgrade, data: PlayerData) -> void:
	var owned := data.unlocked.has(upgrade.id)
	var reachable := upgrade.prerequisite.is_empty() or data.unlocked.has(upgrade.prerequisite)
	disabled = not data.can_unlock(upgrade)
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND

	if owned:
		theme_type_variation = &"OwnedUpgrade"
	elif not reachable:
		theme_type_variation = &"LockedUpgrade"
	elif disabled:
		theme_type_variation = &"UnaffordableUpgrade"
	else:
		theme_type_variation = &"AvailableUpgrade"

	$Locked.visible = not reachable
	$Price.visible = reachable and not owned
	$Price.text = "$%d" % upgrade.cost
	$Price.modulate = get_theme_color(&"price_color")
