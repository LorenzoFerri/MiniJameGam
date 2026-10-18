class_name Player
extends RigidBody3D

signal fuel_changed(amount: float, capacity: float)
signal fuel_empty

@export var thruster_power: float = 1.0
@export var turning_speed: float = 1.0
@export var friction = 0.5
@export var angular_friction: float = 0.5
@export var reverse_power: float = 1.0
@export var fuel_capacity: float = 120.0
@export var forward_fuel_usage: float = 4.0
@export var reverse_fuel_usage: float = 4.0
@export var turn_fuel_usage: float = 1.0

var fuel: float
var engine_power := Vector2(-1.0, -1.0)
var engine_fade: Tween


func configure(data: PlayerData) -> void:
	thruster_power = data.stat(&"thruster_power", thruster_power)
	turning_speed = data.stat(&"turning_speed", turning_speed)
	friction = data.stat(&"friction", friction)
	angular_friction = data.stat(&"angular_friction", angular_friction)
	reverse_power = data.stat(&"reverse_power", reverse_power)
	fuel_capacity = data.stat(&"fuel_capacity", fuel_capacity)
	forward_fuel_usage = data.stat(&"main_fuel_usage", forward_fuel_usage)
	reverse_fuel_usage = data.stat(&"main_fuel_usage", data.stat(&"reverse_fuel_usage", reverse_fuel_usage))
	turn_fuel_usage = data.stat(&"turn_fuel_usage", turn_fuel_usage)
	fuel = fuel_capacity
	fuel_changed.emit(fuel, fuel_capacity)


func refuel(amount: float) -> void:
	fuel = minf(fuel_capacity, fuel + amount)
	fuel_changed.emit(fuel, fuel_capacity)

func _process(_delta: float) -> void:
	%Camera3D.rotation.y = -rotation.y


func _physics_process(delta: float) -> void:
	if fuel <= 0:
		return
	var forward := Input.get_action_strength("accelerate")
	var reverse := Input.get_action_strength("decelerate")
	var left := Input.get_action_strength("turn_left")
	var right := Input.get_action_strength("turn_right")
	_set_engine_power(maxf(forward, reverse * 0.65), maxf(left, right))
	var usage := delta * (forward * forward_fuel_usage + reverse * reverse_fuel_usage + (left + right) * turn_fuel_usage)
	var power := minf(1.0, fuel / usage) if usage > 0 else 1.0
	%ForwardThruster.set_firing(forward > 0)
	%RightSideThruster.set_firing(left > 0)
	%LeftSideThruster.set_firing(right > 0)
	apply_force(transform.basis * (Vector3.FORWARD * forward + Vector3.BACK * reverse * reverse_power) * thruster_power * power)
	apply_torque(transform.basis.y * (left - right) * turning_speed * power)
	apply_force(-linear_velocity * friction)
	apply_torque(-angular_velocity * angular_friction)
	if usage > 0:
		fuel = maxf(0.0, fuel - usage)
		fuel_changed.emit(fuel, fuel_capacity)
		if fuel == 0:
			%ForwardThruster.set_firing(false)
			%RightSideThruster.set_firing(false)
			%LeftSideThruster.set_firing(false)
			_set_engine_power(0.0, 0.0)
			fuel_empty.emit()


func _set_engine_power(main_power: float, side_power: float) -> void:
	var power := Vector2(main_power, side_power)
	if engine_power.is_equal_approx(power):
		return
	engine_power = power
	if engine_fade:
		engine_fade.kill()
	engine_fade = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	engine_fade.tween_property($EngineAudio, "volume_db", lerpf(-29.0, -5.0, main_power), 0.16)
	engine_fade.tween_property($EngineAudio, "pitch_scale", lerpf(0.9, 1.08, main_power), 0.16)
	engine_fade.tween_property($SideThrusterAudio, "volume_db", lerpf(-80.0, -8.0, side_power), 0.16)
	engine_fade.tween_property($SideThrusterAudio, "pitch_scale", lerpf(0.9, 1.08, side_power), 0.16)


func _on_body_entered(_body: Node) -> void:
	GameAudio.play(&"Impact")
