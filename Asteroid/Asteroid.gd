extends CharacterBody3D

signal escaped(asteroid: CharacterBody3D)

@export var min_speed: float = 0.5
@export var max_speed: float = 2.0

var speed: float
var direction := Vector3.FORWARD

func _ready() -> void:
	scale = randf_range(1.0, 5.0) * Vector3.ONE
	speed = randf_range(min_speed, max_speed)

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(direction * delta * speed)
	if collision:
		direction = direction.bounce(collision.get_normal()).normalized()
	
	if global_position.distance_to(GameManager.player.global_position) > 50:
		set_physics_process(false)
		escaped.emit(self)
