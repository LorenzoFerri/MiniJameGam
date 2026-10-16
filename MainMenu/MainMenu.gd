extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%NewGame.pressed.connect(SignalBus.new_game.emit)
	%Credits.pressed.connect(SignalBus.credits.emit)
	%Exit.pressed.connect(func (): get_tree().quit())
