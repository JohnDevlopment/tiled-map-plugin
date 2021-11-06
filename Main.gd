extends Node2D

const ImportTilemap = preload('res://addons/tiled_map_loader/OpenTilemapDlg.tscn')

var _import_dlg

func _ready() -> void:
	_import_dlg = ImportTilemap.instance()
	add_child(_import_dlg)
	
	$Label.text = str("result of loading tilemap: ", $TiledMapLoader.build_auto())
	
	print("")

func _on_Button_pressed() -> void:
	_import_dlg.show_dialog()
