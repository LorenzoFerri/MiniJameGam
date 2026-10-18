extends Node3D

const ASTEROID_SCENE := preload("res://Asteroid/Asteroid.tscn")
const JUNK_SCENE := preload("res://Junk/Junk.tscn")
@export var max_asteroids: int = 10
@export var junk_count: int = 24
@export var junk_spawn_min_radius: float = 10.0
@export var junk_spawn_max_radius: float = 35.0

var cargo: Array[Junk] = []
var run_earnings: int = 0
var run_active: bool = true

@onready var player: Player = $Rocket
@onready var data: PlayerData = GameManager.player_data


func _ready() -> void:
	GameAudio.play(&"Launch")
	GameManager.player = player
	$HUD.setup($Junkyard)
	player.fuel_changed.connect($HUD.update_fuel)
	player.fuel_empty.connect(_end_run)
	player.configure(data)
	for i in junk_count:
		_spawn_junk()
	$Junkyard.body_entered.connect(_start_delivery)
	$Junkyard.body_exited.connect(_stop_delivery)
	$Junkyard.body_entered.connect(_set_end_run_prompt.bind(true))
	$Junkyard.body_exited.connect(_set_end_run_prompt.bind(false))
	$Junkyard/VisibleOnScreenNotifier3D.screen_entered.connect($HUD.set_compass_visible.bind(false))
	$Junkyard/VisibleOnScreenNotifier3D.screen_exited.connect($HUD.set_compass_visible.bind(true))
	data.changed.connect(_refresh_hud)
	_refresh_hud()
	for i in max_asteroids:
		_spawn_asteroid()


func _exit_tree() -> void:
	GameManager.player = null


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"end_run") and run_active and $Junkyard.overlaps_body(GameManager.player):
		get_viewport().set_input_as_handled()
		_end_run()


func _set_end_run_prompt(body: Node3D, visible: bool) -> void:
	if body == GameManager.player:
		$HUD.set_end_run_visible(visible)


func _collect(junk: Junk) -> void:
	if not run_active or junk.picked_up or cargo.size() >= data.capacity():
		return
	cargo.append(junk)
	junk.attach()
	ButtonParticles.burst_at_world(junk.global_position + Vector3.UP)
	GameAudio.play(&"Pickup")
	_refresh_hud()
	if $Junkyard.overlaps_body(junk):
		junk.start_delivery()


func _start_delivery(body: Node3D) -> void:
	if body is Junk and run_active and cargo.has(body):
		body.start_delivery()


func _stop_delivery(body: Node3D) -> void:
	if body is Junk and cargo.has(body):
		body.stop_delivery()


func _deposit(junk: Junk) -> void:
	if not run_active or not cargo.has(junk) or not $Junkyard.overlaps_body(junk):
		return
	cargo.erase(junk)
	var payout := roundi(data.stat(&"scrap_value", junk.resource.value) + data.stat(&"delivery_bonus", 0.0))
	run_earnings += payout
	data.earn(payout)
	$Junkyard.show_delivery()
	ButtonParticles.burst_at_world(junk.global_position + Vector3.UP)
	GameAudio.play(&"Deposit")
	player.refuel(data.stat(&"fuel_per_delivery", 0.0))
	junk.queue_free()
	_spawn_junk.call_deferred()


func _spawn_junk() -> void:
	var junk := JUNK_SCENE.instantiate()
	var angle := randf() * TAU
	var radius := sqrt(randf_range(junk_spawn_min_radius ** 2, junk_spawn_max_radius ** 2))
	junk.position = $Junkyard.position + Vector3(cos(angle), 0, sin(angle)) * radius
	junk.pickup_requested.connect(_collect)
	junk.delivery_completed.connect(_deposit)
	$JunkItems.add_child(junk)
	junk.set_pickup_enabled(run_active and cargo.size() < data.capacity())


func _refresh_hud() -> void:
	$HUD.refresh(data, cargo.size())
	for junk: Junk in $JunkItems.get_children():
		junk.set_pickup_enabled(run_active and cargo.size() < data.capacity())


func _end_run() -> void:
	if not run_active:
		return
	run_active = false
	$HUD.finish_run()
	SignalBus.round_end.emit(run_earnings)


func _spawn_asteroid() -> void:
	var asteroid := ASTEROID_SCENE.instantiate()
	var angle := randf() * TAU
	asteroid.direction = Vector3(cos(angle), 0, sin(angle))
	# Start upstream, outside the camera, but inside the despawn radius.
	var sideways := Vector3(-asteroid.direction.z, 0, asteroid.direction.x)
	asteroid.position = player.position - asteroid.direction * 35.0 + sideways * randf_range(-20, 20)
	asteroid.escaped.connect(_replace_asteroid, CONNECT_DEFERRED)
	$Asteroids.add_child(asteroid)


func _replace_asteroid(asteroid: CharacterBody3D) -> void:
	asteroid.queue_free()
	if run_active:
		_spawn_asteroid()
