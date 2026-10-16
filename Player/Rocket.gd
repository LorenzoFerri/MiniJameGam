class_name Player
extends RigidBody3D

@export var thruster_power = 1
@export var turning_speed = 1
@export var friction = 0.5

func _process(_delta: float) -> void:
	%Camera3D.rotation.y = -rotation.y
	#%Camera3D.position.x = lerp(%Camera3D.position.x, position.x, 0.1)
	#%Camera3D.position.z = lerp(%Camera3D.position.z, position.z, 0.1)
	
func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("accelerate"):
		%ForwardThruster.emitting = true
		apply_force(transform.basis * Vector3.FORWARD * thruster_power)
	else:
		%ForwardThruster.emitting = false
	if Input.is_action_pressed("decelerate"):
		apply_force(transform.basis * Vector3.BACK * thruster_power)
	if Input.is_action_pressed("turn_left"):
		%RightSideThruster.emitting = true
		apply_torque(transform.basis.y * turning_speed)
	else:
		%RightSideThruster.emitting = false
	if Input.is_action_pressed("turn_right"):
		%LeftSideThruster.emitting = true
		apply_torque(transform.basis.y * -turning_speed)
	else:
		%LeftSideThruster.emitting = false
	apply_force(-linear_velocity * friction)
	apply_torque(-angular_velocity * friction)
