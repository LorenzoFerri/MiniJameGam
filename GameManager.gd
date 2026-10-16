extends Node

var asteroid_direction = Vector2(-1,1)
var asteroid_count: int = 0
var player: Player

func _ready() -> void:
	SignalBus.new_game.connect(new_game)


func new_game() -> void:
	get_tree().change_scene_to_file("res://Level/Level.tscn")
