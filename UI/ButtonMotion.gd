extends Node
## Event-driven feedback shared by mouse, keyboard and controller navigation.

@export var hover_scale: float = 1.025
@export var press_scale: float = 0.975
@export var duration: float = 0.14

var motion: Tween
var was_highlighted := false
@onready var button: BaseButton = get_parent()


func _ready() -> void:
	button.resized.connect(_update_pivot)
	button.mouse_entered.connect(_refresh)
	button.mouse_exited.connect(_refresh)
	button.focus_entered.connect(_refresh)
	button.focus_exited.connect(_refresh)
	button.button_down.connect(_animate.bind(press_scale))
	button.button_up.connect(_refresh)
	button.pressed.connect(_refresh, CONNECT_DEFERRED)
	button.pressed.connect(GameAudio.play.bind(&"Click"))
	_update_pivot()


func _update_pivot() -> void:
	button.pivot_offset = button.size * 0.5


func _refresh() -> void:
	var highlighted := not button.disabled and (button.is_hovered() or button.has_focus())
	if highlighted and not was_highlighted:
		GameAudio.play(&"Hover")
	was_highlighted = highlighted
	_animate(hover_scale if highlighted else 1.0)


func _animate(amount: float) -> void:
	if motion:
		motion.kill()
	motion = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(button, "scale", Vector2.ONE * amount, duration)
