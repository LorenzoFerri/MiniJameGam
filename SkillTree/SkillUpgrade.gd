class_name SkillUpgrade
extends Resource

@export var id: StringName
@export var effect: String
@export var cost: int = 10
@export var prerequisite: StringName
@export var stat: StringName
@export var addition: float = 0.0
@export var multiplier: float = 1.0
