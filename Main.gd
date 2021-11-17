extends Node2D

const CAMERA_SPEED := 50

export var build_tilemap := false

onready var camera = $Camera2D
onready var tilemap_loader = $TiledMapLoader
onready var debug_console = $CanvasLayer/DebugConsole

func _ready() -> void:
	if build_tilemap:
		var err = tilemap_loader.build_auto()
		if err == null:
			tilemap_loader.queue_free()
			print('failed')

func _unhandled_key_input(event: InputEventKey) -> void:
	if event.is_action_pressed('ui_debug'):
		get_tree().set_input_as_handled()
		debug_console.activate()

func _process(delta: float) -> void:
	var vec : Vector2 = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	if vec != Vector2.ZERO:
		var offset : Vector2 = vec * CAMERA_SPEED * delta
		camera.position.x = clamp(camera.position.x + offset.x, camera.limit_left, camera.limit_right)
		camera.position.y = clamp(camera.position.y + offset.y, camera.limit_top, camera.limit_bottom)
