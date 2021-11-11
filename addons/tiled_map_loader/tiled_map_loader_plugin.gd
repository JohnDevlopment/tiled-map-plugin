tool
extends EditorPlugin

var _new_tileset_dialog
var _load_tilemap_dialog
var _import_plugin: EditorImportPlugin

func _enter_tree() -> void:
	add_custom_type('TiledMapLoader', 'Node2D', preload('res://addons/tiled_map_loader/tiled_map_loader.gd'), null)
	
	# Load tileset dialog
	_new_tileset_dialog = preload('res://addons/tiled_map_loader/NewTilesetDialog.tscn').instance()
	get_editor_interface().get_file_system_dock().add_child(_new_tileset_dialog)
	
	# Load tilemap dialog
	_load_tilemap_dialog = preload('res://addons/tiled_map_loader/OpenTilemapDlg.tscn').instance()
	get_editor_interface().get_file_system_dock().add_child(_load_tilemap_dialog)
	
	# Tool menu items
	add_tool_menu_item('Import Tiled Tileset', self, '_show_new_tileset_dialog')
	add_tool_menu_item('Import Tiled Tilemap', self, '_show_load_tilemap_dialog')
	
	# Project setting: initial directory
	if not ProjectSettings.has_setting('tiled_map_loader/initial_dir'):
		ProjectSettings.set_setting('tiled_map_loader/initial_dir', 'res://')
		ProjectSettings.add_property_info({
			name = 'tiled_map_loader/initial_dir',
			type = TYPE_STRING,
			hint = PROPERTY_HINT_DIR
		})
	
	# Project setting: enable JSON format
	if not ProjectSettings.has_setting('tiled_map_loader/enable_json_format'):
		ProjectSettings.set_setting('tiled_map_loader/enable_json_format', false)
		ProjectSettings.add_property_info({
			name = 'tiled_map_loader/enable_json_format',
			type = TYPE_BOOL
		})
	
	# Import plugin
#	_import_plugin = preload('res://addons/tiled_map_loader/tiled_map_loader_import_plugin.gd').new()
#	add_import_plugin(_import_plugin)

func _exit_tree() -> void:
	remove_tool_menu_item('Import Tiled Tileset')
	remove_tool_menu_item('Import Tiled Tilemap')
	
	remove_custom_type('TiledMapLoader')
	
#	remove_import_plugin(_import_plugin)
	
	# Remove dialogs from editor interface
	_load_tilemap_dialog.queue_free()
	_load_tilemap_dialog = null
	
	_new_tileset_dialog.queue_free()
	_new_tileset_dialog = null

func _show_new_tileset_dialog(_ud) -> void:
	(_new_tileset_dialog as Popup).show_dialog()
	(_new_tileset_dialog as Popup).editor_interface = get_editor_interface()

func _show_load_tilemap_dialog(_ud) -> void:
	_load_tilemap_dialog.show_dialog()
	_load_tilemap_dialog.editor_interface = get_editor_interface()

func get_plugin_name() -> String:
	return "Tiled Map Loader"
