extends Control

func _ready() -> void:
	%Earnings.text = "+$%d" % GameManager.last_run_earnings
	resized.connect(_layout_stage)
	_layout_stage()
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)


func _layout_stage() -> void:
	$Stage.position = size * 0.5 + Vector2(0, 12)
	$Stage.scale = Vector2.ONE * minf(1.0, minf(size.x / 600.0, size.y / 600.0))


func _on_animation_finished(_animation: StringName) -> void:
	Interface.change_scene("res://SkillTree/SkillTree.tscn")
