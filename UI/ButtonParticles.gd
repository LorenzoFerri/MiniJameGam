extends Node

const CLICK_BURST := preload("res://UI/ClickBurst.tscn")


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var on_input := _on_button_input.bind(node)
		if not node.gui_input.is_connected(on_input):
			node.gui_input.connect(on_input)


func _on_button_input(event: InputEvent, button: BaseButton) -> void:
	if button.disabled:
		return

	var local_position: Vector2
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		local_position = event.position
	elif event.is_action_pressed(&"ui_accept") and not event.is_echo():
		local_position = button.size * 0.5
	else:
		return

	_spawn_burst(button.get_global_transform_with_canvas() * local_position, button.get_viewport())


func burst_at_world(position: Vector3) -> void:
	var viewport := get_viewport()
	_spawn_burst(viewport.get_camera_3d().unproject_position(position), viewport)


func _spawn_burst(position: Vector2, viewport: Viewport) -> void:
	var burst := CLICK_BURST.instantiate()
	var sparks: GPUParticles2D = burst.get_node("Sparks")
	sparks.position = position
	# Belongs to the button's viewport, so it also works in dialogs and survives scene changes.
	viewport.add_child(burst)
	sparks.restart()
