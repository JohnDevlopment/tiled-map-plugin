tool
extends EditorImportPlugin

enum Presets { DEFAULT, PIXEL_ART }

func get_import_options(preset: int) -> Array:
	return [
		{
			name = 'image_flags',
			default_value = 0 if preset == Presets.PIXEL_ART else Texture.FLAGS_DEFAULT,
			property_hint = PROPERTY_HINT_FLAGS,
			hint_string = 'Mipmaps,Repeat,Filter,Anisotropic,SRGB,Mirrored Repeat,Video Surface'
		},
		{
			name = 'collision_layer',
			default_value = 0,
			property_hint = PROPERTY_HINT_LAYERS_2D_PHYSICS
		},
		{
			name = 'add_background',
			default_value = false
		},
		{
			name = 'embed_internal_images',
			default_value = true if preset == Presets.PIXEL_ART else false
		},
		{
			name = 'columns',
			default_value = 0,
			property_hint = PROPERTY_HINT_RANGE,
			hint_string = '-1,100,or_greater'
		},
		{
			name = 'margin',
			default_value = 0,
			property_hint = PROPERTY_HINT_RANGE,
			hint_string = '0,100,or_greater'
		},
		{
			name = 'spacing',
			default_value = 0,
			property_hint = PROPERTY_HINT_RANGE,
			hint_string = '0,100,or_greater'
		}
	]

func get_importer_name() -> String: return "tiled_map_loader.importer"

func get_option_visibility(option: String, options: Dictionary) -> bool: return true

func get_preset_count() -> int: return Presets.size()

func get_preset_name(preset: int) -> String:
	match preset:
		Presets.DEFAULT:
			return "Default"
		Presets.PIXEL_ART:
			return "Pixel Art"
	# Should be unreachable
	printerr("Unreachable code encountered in get_preset_name()")
	return ''

func get_recognized_extensions() -> Array:
	var exts := ['tsx', 'tmx']
	
	if ProjectSettings.get_setting('tiled_map_loader/enable_json_format'):
		exts.push_back('json')
		
	return exts

func get_resource_type() -> String: return 'Node'

func get_save_extension() -> String: return 'tres'

func get_visible_name() -> String: return 'Import Tiled Maps/Tilesets'

func import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array) -> int:
	
	
	
	return OK
