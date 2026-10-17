class_name Junk
extends RigidBody3D

signal pickup_requested(junk: Junk)
signal delivery_completed(junk: Junk)

@export var resource: JunkResource
@export var models: Dictionary[PackedScene, Transform3D]

var picked_up = false
var pickup_enabled: bool = false
const FRICTION = 0.2
const PULL_STRENGTH = 0.5

@onready var rope_length = randf_range(4.0, 6.0)
@onready var pickup_time: float = %PickUpTimer.wait_time
@onready var rope_path: Path3D = $RopePath
@onready var rope_mesh: CSGPolygon3D = $RopePath/RopeMesh

const ROPE_SEGMENTS = 16
const MAX_SAG = 5.0

func _ready() -> void:
	var selected_model: PackedScene = models.keys().pick_random()
	var model: Node3D = selected_model.instantiate()
	model.transform = models[selected_model]
	$Visual.add_child(model)

	var data: PlayerData = GameManager.player_data
	pickup_time = data.stat(&"pickup_time", pickup_time)
	if pickup_time > 0:
		%PickUpTimer.wait_time = pickup_time
	var pickup_shape: SphereShape3D = %PickUpArea.get_node("CollisionShape3D").shape
	pickup_shape.radius = data.stat(&"pickup_radius", pickup_shape.radius)
	%PickUpArea.body_entered.connect(_on_body_enter_pick_up_area)
	%PickUpArea.body_exited.connect(_on_body_exit_pick_up_area)
	%PickUpTimer.timeout.connect(_pick_up_junk)
	%DeliveryTimer.timeout.connect(delivery_completed.emit.bind(self))
	rotation_degrees = Vector3(randf() * 360, randf() * 360, randf() * 360)

func _physics_process(_delta: float) -> void:
	if picked_up:
		var to_player := GameManager.player.global_position - global_position
		var current_distance := to_player.length()
		if current_distance > rope_length:
			apply_force(to_player * PULL_STRENGTH)
	apply_force(-linear_velocity * FRICTION)

func _process(_delta: float) -> void:
	%ProgressSprite.global_position = global_position + Vector3.UP
	var timer: Timer = %DeliveryTimer if picked_up else %PickUpTimer
	%ProgressBar.value = 1.0 - timer.time_left / timer.wait_time
	
	if picked_up:
		rope_path.show()
		_update_rope()
	else:
		rope_path.hide()
	
func _on_body_enter_pick_up_area(body: Node3D):
	if body is Player and not picked_up:
		_start_pickup()
		
func _on_body_exit_pick_up_area(body: Node3D):
	if body is Player and not picked_up:
		%ProgressSprite.hide()
		%PickUpTimer.stop()

func _pick_up_junk():
	if not pickup_enabled or picked_up:
		return
	%ProgressSprite.hide()
	pickup_requested.emit(self)


func set_pickup_enabled(enabled: bool) -> void:
	if pickup_enabled == enabled:
		return
	pickup_enabled = enabled
	if picked_up:
		return
	if not enabled:
		%PickUpTimer.stop()
		%ProgressSprite.hide()
	elif %PickUpArea.overlaps_body(GameManager.player):
		_start_pickup()


func _start_pickup() -> void:
	if not pickup_enabled or picked_up:
		return
	if pickup_time == 0:
		_pick_up_junk()
	else:
		%ProgressSprite.show()
		%PickUpTimer.start()


func attach() -> void:
	picked_up = true
	%PickUpTimer.stop()
	%ProgressSprite.hide()


func start_delivery() -> void:
	%ProgressSprite.show()
	%DeliveryTimer.start()


func stop_delivery() -> void:
	%DeliveryTimer.stop()
	%ProgressSprite.hide()

func _update_rope() -> void:
	var curve := Curve3D.new()
	var p_start = global_position
	var p_end = GameManager.player.global_position
	var current_distance = p_start.distance_to(p_end)
	var slack_ratio = clamp(current_distance / rope_length, 0.0, 1.0)
	var current_sag = (1.0 - slack_ratio) * MAX_SAG
	var mid_point = (p_start + p_end) / 2.0
	var control_point = mid_point + (Vector3.DOWN * current_sag)
	for i in range(ROPE_SEGMENTS + 1):
		var t = float(i) / float(ROPE_SEGMENTS)
		var q0 = p_start.lerp(control_point, t)
		var q1 = control_point.lerp(p_end, t)
		var bezier_point = q0.lerp(q1, t)
		curve.add_point(bezier_point)
	rope_path.curve = curve
