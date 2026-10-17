class_name PlayerData
extends Resource

const UPGRADES := preload("res://SkillTree/Upgrades.tres")

@export var money: int = 0
@export var unlocked: Array[StringName] = []
@export var base_capacity: int = 2


func capacity() -> int:
	return int(stat(&"capacity", base_capacity))


func stat(key: StringName, base: float) -> float:
	for upgrade: SkillUpgrade in UPGRADES.upgrades:
		if upgrade.stat == key and unlocked.has(upgrade.id):
			base = (base + upgrade.addition) * upgrade.multiplier
	return base


func can_unlock(upgrade: SkillUpgrade) -> bool:
	return not unlocked.has(upgrade.id) and money >= upgrade.cost and (upgrade.prerequisite.is_empty() or unlocked.has(upgrade.prerequisite))


func unlock(upgrade: SkillUpgrade) -> void:
	if not can_unlock(upgrade):
		return
	money -= upgrade.cost
	unlocked.append(upgrade.id)
	emit_changed()


func earn(amount: int) -> void:
	money += amount
	emit_changed()
