extends Control


func _ready() -> void:
	%Title.text = ProjectSettings.get_setting("application/config/name")
	%NewGame.pressed.connect(SignalBus.new_game.emit)
	%Credits.pressed.connect(func(): %IconCredits.popup_centered(Vector2i(420, 200)))
	%IconCredits.visibility_changed.connect(_on_credits_visibility_changed)
	%Exit.pressed.connect(func (): get_tree().quit())
	%NewGame.grab_focus()


func _on_credits_visibility_changed() -> void:
	%DialogShade.visible = %IconCredits.visible
