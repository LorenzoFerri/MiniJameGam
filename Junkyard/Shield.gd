class_name DepotShield
extends StaticBody3D

@export var impact_duration: float = 0.7
var impact: Tween
@onready var surface: ShaderMaterial = $MeshInstance3D.material_override


func hit(world_position: Vector3) -> void:
	surface.set_shader_parameter("impact_origin", to_local(world_position))
	if impact:
		impact.kill()
	impact = create_tween()
	impact.tween_method(_set_impact_progress, 0.0, 1.0, impact_duration)


func _set_impact_progress(value: float) -> void:
	surface.set_shader_parameter("impact_progress", value)
