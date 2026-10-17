class_name JunkResource
extends Resource

enum Tier {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var tier: Tier = Tier.COMMON
@export_range(1, 1000) var value: int = 10
