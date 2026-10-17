extends Node

const STARTING_DATA := preload("res://Player/StartingData.tres")

var player_data: PlayerData = STARTING_DATA.duplicate(true)
var player: Player
var last_run_earnings: int = 0

func _ready() -> void:
	SignalBus.new_game.connect(new_game)
	SignalBus.round_start.connect(start_run)
	SignalBus.round_end.connect(_finish_run)


func new_game() -> void:
	player_data = STARTING_DATA.duplicate(true)
	start_run()


func start_run() -> void:
	last_run_earnings = 0
	Interface.change_scene("res://Level/Level.tscn")


func _finish_run(earnings: int) -> void:
	last_run_earnings = earnings
	if earnings > 0:
		Interface.change_scene("res://RunEnd/RunEnd.tscn")
	else:
		Interface.change_scene("res://SkillTree/SkillTree.tscn")
