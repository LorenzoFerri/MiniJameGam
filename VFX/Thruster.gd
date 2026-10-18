extends GPUParticles3D


func set_firing(firing: bool) -> void:
	if emitting == firing:
		return
	emitting = firing
	$Core.visible = firing
	$Sparks.emitting = firing
	$Light.visible = firing
	if firing:
		$AnimationPlayer.play(&"thrust")
	else:
		$AnimationPlayer.stop()
