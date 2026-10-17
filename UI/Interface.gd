extends CanvasLayer

signal transition_finished
signal pause_changed(paused: bool)

const BUTTON_MOTION := preload("res://UI/ButtonMotion.gd")
const MAIN_MENU := "res://MainMenu/MainMenu.tscn"

@export var fade_out_duration: float = 0.16
@export var fade_in_duration: float = 0.22

var transitioning := false
var pause_open := false
var previous_focus: Control

@onready var resume_button: Button = %PauseMenu.get_node("%Resume")
@onready var menu_button: Button = %PauseMenu.get_node("%MainMenu")


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	resume_button.pressed.connect(toggle_pause)
	menu_button.pressed.connect(change_scene.bind(MAIN_MENU))
	_attach_button_motion(resume_button)
	_attach_button_motion(menu_button)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		if transitioning or get_tree().current_scene.scene_file_path == MAIN_MENU:
			return
		get_viewport().set_input_as_handled()
		toggle_pause()


func toggle_pause() -> void:
	if transitioning:
		return
	pause_open = not pause_open
	if pause_open:
		previous_focus = get_viewport().gui_get_focus_owner()
		%PauseMenu.show()
		get_tree().paused = true
		resume_button.grab_focus()
	else:
		%PauseMenu.hide()
		get_tree().paused = false
		if is_instance_valid(previous_focus):
			previous_focus.grab_focus()
		else:
			resume_button.release_focus()
		previous_focus = null
	pause_changed.emit(pause_open)


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_node("ButtonMotion"):
		node.ready.connect(_attach_button_motion.bind(node), CONNECT_ONE_SHOT)


func _attach_button_motion(button: BaseButton) -> void:
	var feedback := Node.new()
	feedback.name = "ButtonMotion"
	feedback.set_script(BUTTON_MOTION)
	button.add_child(feedback)


func change_scene(path: String) -> void:
	if transitioning:
		return
	transitioning = true
	get_tree().paused = true
	$Curtain.show()
	var fade := create_tween().set_trans(Tween.TRANS_SINE)
	fade.tween_property($Curtain, "color:a", 1.0, fade_out_duration)
	await fade.finished
	%PauseMenu.hide()
	pause_open = false
	previous_focus = null
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await RenderingServer.frame_post_draw
	fade = create_tween().set_trans(Tween.TRANS_SINE)
	fade.tween_property($Curtain, "color:a", 0.0, fade_in_duration)
	await fade.finished
	$Curtain.hide()
	get_tree().paused = false
	transitioning = false
	transition_finished.emit()
