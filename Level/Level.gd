extends Node3D

const ASTEROID_SCENE := preload("res://Asteroid/Asteroid.tscn")
const MAX_ASTEROID = 10
@onready var player = $Rocket

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.player = player


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameManager.asteroid_count < MAX_ASTEROID:
		var asteroid_instance = ASTEROID_SCENE.instantiate()
		var position_offset_2d = -GameManager.asteroid_direction * 50
		var is_in_frustum = true
		while is_in_frustum:
			position_offset_2d += Vector2(randi_range(-30,30), randi_range(-30,30))
			asteroid_instance.position = player.position + Vector3(position_offset_2d.x, 0, position_offset_2d.y)
			is_in_frustum = get_viewport().get_camera_3d().is_position_in_frustum(asteroid_instance.position)
		add_child(asteroid_instance)
		GameManager.asteroid_count += 1
	
