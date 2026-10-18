extends CanvasLayer

@export var compass_radius: float = 4.5
@export_range(-180.0, 0.0) var fuel_empty_angle: float = -55.0
@export_range(0.0, 180.0) var fuel_full_angle: float = 55.0

var depot: Node3D
var low_fuel := false
var cargo_full := false
var at_depot := false


func setup(destination: Node3D) -> void:
	depot = destination


func update_fuel(amount: float, capacity: float) -> void:
	var ratio := clampf(amount / capacity, 0.0, 1.0)
	%FuelNeedle.rotation_degrees = lerpf(fuel_empty_angle, fuel_full_angle, ratio)
	%FuelValue.text = "%d%%" % floori(ratio * 100.0)
	var warning_active := ratio < 0.2
	if low_fuel != warning_active:
		low_fuel = warning_active
		%FuelVignette.visible = low_fuel
		if low_fuel:
			%LowFuelPulse.play(&"low_fuel")
		else:
			%LowFuelPulse.stop()
	_refresh_warnings()


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
	at_depot = visible
	_refresh_warnings()


func refresh(data: PlayerData, cargo_count: int) -> void:
	%Money.text = str(data.money)
	%Load.text = "%d / %d" % [cargo_count, data.capacity()]
	cargo_full = cargo_count >= data.capacity()
	_refresh_warnings()


func _refresh_warnings() -> void:
	%FuelWarning.visible = low_fuel
	%CargoWarning.visible = cargo_full and not at_depot
	%ReturnPrompt.visible = (low_fuel or cargo_full) and not at_depot
	%Warnings.visible = low_fuel or %CargoWarning.visible
