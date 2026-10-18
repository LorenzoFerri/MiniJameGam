extends Area3D

@export var delivery_flash_duration: float = 0.7
var delivery_flash: Tween
@onready var surface: ShaderMaterial = $MeshInstance3D.material_override


func show_delivery() -> void:
	if delivery_flash:
		delivery_flash.kill()
	delivery_flash = create_tween().set_trans(Tween.TRANS_SINE)
	delivery_flash.tween_method(_set_delivery_glow, 1.0, 0.0, delivery_flash_duration)


func _set_delivery_glow(value: float) -> void:
	surface.set_shader_parameter("delivery_glow", value)
