extends CanvasLayer
## Shared animated background. Assign a world target to enable flight parallax.

@export var parallax_target: Node3D

@onready var space_material: ShaderMaterial = $Background.material


func _ready() -> void:
	set_process(parallax_target != null)
	if is_processing():
		_update_parallax()


func _process(_delta: float) -> void:
	_update_parallax()


func _update_parallax() -> void:
	var world_position := parallax_target.global_position
	space_material.set_shader_parameter("viewer_position", Vector2(world_position.x, world_position.z))
