extends CanvasLayer

@export var compass_radius: float = 4.5

var depot: Node3D


func setup(destination: Node3D) -> void:
	depot = destination


func update_fuel(amount: float, capacity: float) -> void:
	%Fuel.max_value = capacity
	%Fuel.value = amount


func _process(_delta: float) -> void:
	if %Compass.visible:
		var camera := get_viewport().get_camera_3d()
		var player_position := GameManager.player.global_position
		var direction := player_position.direction_to(depot.global_position)
		%Compass.position = camera.unproject_position(player_position + direction * compass_radius)
		%Compass.rotation = (camera.unproject_position(depot.global_position) - %Compass.position).angle() + PI / 2.0


func set_compass_visible(visible: bool) -> void:
	%Compass.visible = visible


func set_end_run_visible(visible: bool) -> void:
	%EndRun.visible = visible


func refresh(data: PlayerData, cargo_count: int) -> void:
	%Money.text = "$%d" % data.money
	%Load.text = "%d/%d" % [cargo_count, data.capacity()]
