extends CharacterBody3D

var speed: float

func _ready() -> void:
	scale = randf_range(1.0, 5.0) * Vector3.ONE
	speed = randf_range(1.0, 4.0)

func _physics_process(delta: float) -> void:
	var direction = Vector3(GameManager.asteroid_direction.x, 0, GameManager.asteroid_direction.y)
	move_and_collide(direction * delta * speed)
	
	if position.distance_to(GameManager.player.position) > 50:
		queue_free()
		GameManager.asteroid_count -= 1
