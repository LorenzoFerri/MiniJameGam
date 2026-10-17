extends Control

signal view_changed

@export var zoom_min: float = 0.35
@export var zoom_max: float = 3.0
@export var zoom_step: float = 1.15

var panning: bool = false
var previous_size: Vector2
var auto_frame := true

@onready var tree: Control = $Tree


func _ready() -> void:
	get_window().focus_exited.connect(_stop_pan)
	Interface.pause_changed.connect(_on_pause_changed)
	_initialize_view.call_deferred()


func _initialize_view() -> void:
	frame_tree()
	resized.connect(_resize_view)


func frame_tree() -> void:
	auto_frame = true
	_fit_tree()


func _fit_tree() -> void:
	var fit := clampf(minf((size.x - 32) / tree.size.x, (size.y - 32) / tree.size.y), zoom_min, 1.0)
	tree.scale = Vector2.ONE * fit
	tree.position = (size - tree.size * fit) / 2.0
	previous_size = size
	view_changed.emit()


func _resize_view() -> void:
	if auto_frame:
		_fit_tree()
		return
	tree.position += (size - previous_size) / 2.0
	previous_size = size
	view_changed.emit()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_HOME:
		frame_tree()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var inside := get_global_rect().has_point(event.position)
		if event.button_index == MOUSE_BUTTON_MIDDLE and ((event.pressed and inside) or panning):
			panning = event.pressed
			if panning:
				auto_frame = false
			view_changed.emit()
			get_viewport().set_input_as_handled()
		elif inside and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			auto_frame = false
			var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			var anchor: Vector2 = (point - tree.position) / tree.scale.x
			var factor := zoom_step if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / zoom_step
			tree.scale = Vector2.ONE * clampf(tree.scale.x * factor, zoom_min, zoom_max)
			tree.position = point - anchor * tree.scale.x
			view_changed.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and panning:
		tree.position += event.relative
		view_changed.emit()
		get_viewport().set_input_as_handled()


func _stop_pan() -> void:
	panning = false


func _on_pause_changed(paused: bool) -> void:
	if paused:
		_stop_pan()
		view_changed.emit()
