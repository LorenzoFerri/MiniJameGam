extends RigidBody3D

@export var thruster_power = 0.5
@export var turning_speed = 0.5
	
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
