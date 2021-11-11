extends Node2D

#const ImportTilemap = preload('res://addons/tiled_map_loader/OpenTilemapDlg.tscn')

const CAMERA_SPEED := 50

#onready var camera = $Camera2D

export var build_tilemap := false

onready var tilemap_loader = $TiledMapLoader

func _ready() -> void:
	if build_tilemap:
		var err : int = tilemap_loader.build_auto()
		if err:
			tilemap_loader.queue_free()
			print('failed')

#func _process(delta: float) -> void:
#	var vec : Vector2 = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
#
#	if vec != Vector2.ZERO:
#		var offset : Vector2 = vec * CAMERA_SPEED * delta
#		camera.position.x = clamp(camera.position.x + offset.x, camera.limit_left, camera.limit_right)
#		camera.position.y = clamp(camera.position.y + offset.y, camera.limit_top, camera.limit_bottom)
