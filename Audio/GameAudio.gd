extends Node
## Shared one-shot sounds. Continuous audio belongs to its scene.

func play(cue: StringName) -> void:
	get_node(NodePath(cue)).play()
