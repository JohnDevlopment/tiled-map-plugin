## Loader of Tiled map files.
# @name TiledMapLoader
tool
extends Node2D

## A class used to read Tiled files and convert into a dictionary.
# @type GDScript
const TiledXMLToDict = preload('res://addons/tiled_map_loader/tiled_xml_to_dict.gd')

## The collision layer of the tilemap(s).
# @type int
var collision_layer := 1

## The collision mask of the tilemap(s).
# @type int
var collision_mask := 1

## A path to a Tiled tilemap file.
# @type String
var tilemap := ''

const ERROR_PREFIX := "Tiled Map Loader: "

# Constants for tile flipping
# http://doc.mapeditor.org/reference/tmx-map-format/#tile-flipping
const FLIPPED_HORIZONTALLY_FLAG = 0x80000000
const FLIPPED_VERTICALLY_FLAG   = 0x40000000
const FLIPPED_DIAGONALLY_FLAG   = 0x20000000

var _tileset_path_to_first_gid := {}
var _loaded_templates := {}

const WHITELIST_PROPERTIES := PoolStringArray([
	"backgroundcolor",
	"compression",
	"draworder",
	"gid",
	"height",
	"imageheight",
	"imagewidth",
	"infinite",
	"margin",
	"name",
	"orientation",
	"probability",
	"spacing",
	"tilecount",
	"tiledversion",
	"tileheight",
	"tilewidth",
	"type",
	"version",
	"visible",
	"width",
])

func _get(property: String):
	match property:
		'tilemap':
			return tilemap
		'collision_layer':
			return collision_layer
		'collision_mask':
			return collision_mask

func _set(property: String, value) -> bool:
	match property:
		'tilemap':
			tilemap = value
		'collision_layer':
			collision_layer = value
		'collision_mask':
			collision_mask = value
		_:
			return false
	
	return true

func _get_property_list() -> Array:
	return [
		{
			name = 'TiledMapLoader',
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			name = 'tilemap',
			type = TYPE_STRING,
			usage = PROPERTY_USAGE_DEFAULT,
			hint = PROPERTY_HINT_FILE
		},
		{
			name = 'Collision',
			type = TYPE_NIL,
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE,
			hint_string = 'collision_'
		},
		{
			name = 'collision_layer',
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT,
			hint = PROPERTY_HINT_LAYERS_2D_PHYSICS
		},
		{
			name = 'collision_layer',
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT,
			hint = PROPERTY_HINT_LAYERS_2D_PHYSICS
		}
	]

## Builds a tilemap and adds it as a child.
# @desc ...
#
#       @a options is a dictionary that shall have the following keys. Note: format is
#       @code{name (type) -- description <default>}.
#
#       * save_tiled_properties (bool) -- If true, set tiled properties as meta <false> @br
#       * custom_properties (bool) -- If true, set custom properties as meta <false>
func build(source_path: String, options: Dictionary) -> int:
	var err := OK
	reset_global_members()
	
	set_options_defaults(options, {
		save_tiled_properties = false,
		custom_properties = false
	})
	
	# Read and validate tilemap
	var map = read_tilemap_file(source_path)
	if map is int: return map
	
	err = validate_tilemap(map)
	if err: return err
	
	# Build tileset
	var tileset = build_tileset_from_list(map.tilesets, source_path, options)
	if not tileset is Object: return tileset
	
	if options.save_tiled_properties:
		set_tiled_properties_as_meta(self, map)
	
	if options.custom_properties:
		set_custom_properties(self, map)
	
	# Global map data
	var map_data := {
		tileset = tileset,
		cell_size = Vector2(map.tilewidth, map.tileheight),
		options = options
	}
	
	for layer in map.layers:
		err = create_layer(layer, map_data)
		if err: return err
	
	return OK

func build_auto(options: Dictionary = {}) -> int:
	return build(tilemap, options)

## Builds a @class TileSet resource from a TSX file.
# @desc Reads a TSX file located at @a source_path and returns a @class TileSet resource based
#       off of it. If there is an error, then an int is returned instead.
func build_tileset(source_path: String, options: Dictionary = {}):
	var tileset = read_tileset_file(source_path)
	if not tileset is Dictionary:
		return tileset
	
	tileset['firstgid'] = 0
	
	return build_tileset_from_list([tileset], source_path, options)

## Builds a @class TileSet resource from a TSX file.
# @desc Reads a TSX file located at @a source_path and returns a @class TileSet resource based
#       off of it. If there is an error, then an int is returned instead. @a tilesets is a list of
#       tileset dictionaries in the format that would be returned by @function read_tileset_file().
#
#       You can modify the result of this function through the @a options dictionary. Below
#       Is a list of options you can pass:@br
#       * columns = Limit the number of columns per row in the tileset (default: 0)@br
#       * margin = Add margin around the tileset in pixels (default: 0)@br
#       * spacing = Spacing between tiles in pixels (default: 0)@br
#       * imageflags = Flags from the enum @enum Texture.Flags to set the image with (default: 0)
func build_tileset_from_list(tilesets: Array, source_path: String, options: Dictionary = {}):
	set_options_defaults(options, {
		columns = 0,
		margin = 0,
		spacing = 0,
		imageflags = 0
	})
	
	var err := ERR_INVALID_DATA
	var result := TileSet.new()
	
	for tileset in tilesets:
		var ts: Dictionary = tileset
		var ts_source_path := source_path
		
		if 'source' in ts:
			if not ('firstgid' in ts) or not (ts.firstgid as String).is_valid_integer():
				print_error('Missing or invalid firstgid tileset property')
				return ERR_INVALID_DATA
			
			ts_source_path = source_path.get_base_dir().plus_file(ts.source)
			
			ts = read_tileset_file(ts_source_path)
			if not ts is Dictionary:
				return ts # error happened
			
			ts.firstgid = tileset.firstgid
			
			# NOTE: This is apparently used for templates later on.
			_tileset_path_to_first_gid[ts_source_path] = ts.firstgid
		
		err = validate_tileset(ts)
		if err: return err
		
		# Flags defined in *options*
		var has_global_image: bool = 'image' in ts
		var firstgid: int = int(ts.firstgid)
		var columns: int = int(options.get('columns', -1))
		var margin: int = int(options.get('margin', 0))
		var spacing: int = int(options.get('spacing', 0))
		
		# If tileset is one global image, *image* will be non-null
		var image = null
		var image_size := Vector2.ZERO
		
		if has_global_image:
			image = load_image(ts.image, ts_source_path)
			if not image is Object:
				return image # error happened
			image_size = Vector2(int(ts.imagewidth), int(ts.imageheight))
			image.flags = 0
		
		var tile_count: int = ts.tilecount
		var tile_size := Vector2(int(ts.tilewidth), int(ts.tileheight))
		
		var gid := firstgid
		var x := margin
		var y := margin
		
		var column := 0
		for i in range(tile_count):
			var tile_pos := Vector2(x, y)
			var region := Rect2(tile_pos, tile_size)
			
			var rel_id := str(gid - firstgid)
			
			result.create_tile(gid)
			
			if has_global_image:
				result.tile_set_texture(gid, image)
				result.tile_set_region(gid, region)
				
				var apply_offset: bool = options.get('apply_offset', false)
				if apply_offset:
					result.tile_set_texture_offset(gid, Vector2(0, -tile_size.y))
			elif not gid in ts.tiles:
				# If the tileset is not based on a global image, then each tile
				# is separately created with its own image. But in that case, a
				# tile is not guarrenteed to exist with a specific gid.
				gid += 1
				continue
			else:
				var image_path: String = ts.tiles[rel_id].image
				image = load_image(image_path, ts_source_path)
				if not image is Object:
					return image # error happened
				result.tile_set_texture(gid, image)
				
				var apply_offset: bool = options.get('apply_offset', false)
				if apply_offset:
					result.tile_set_texture_offset(gid, Vector2(0, -image.get_height()))
			
			if 'tiles' in ts and rel_id in ts.tiles and 'objectgroup' in ts.tiles[rel_id] and 'objects' in ts.tiles[rel_id].objectgroup:
				for object in ts.tiles[rel_id].objectgroup.objects:
					var shape = shape_from_object(object)
					if not shape is Shape2D:
						return shape # error happened
					
					match object.type:
						'navigation':
							pass # TODO: add navigation to tileset
						'occluder':
							pass # TODO: add occluder to tileset
						_:
							var offset := Vector2(object.x, object.y)
							var apply_offset: bool = options.get('apply_offset', false)
							
							if apply_offset:
								offset += result.tile_get_texture_offset(gid)
							
							if 'width' in object and 'height' in object:
								offset += Vector2(float(object.width) / 2.0, float(object.height) / 2.0)
							
#							print("result.tile_add_shape(%d, %s, %s, %s" % [gid, shape, Transform2D(0.0, offset), object.type == 'one_way'])
							
							result.tile_add_shape(gid, shape, Transform2D(0.0, offset), object.type == 'one_way')
			
			gid += 1
			column += 1
			x += int(tile_size.x) + spacing
			
			if (columns > 0 and column >= columns) or x >= int(image_size.x) - margin or (x + int(tile_size.x)) > int(image_size.x):
				x = margin
				y += int(tile_size.y) + spacing
				column = 0
		
		# Name of the tileset
		if str(ts.name) != '':
			result.resource_name = str(ts.name)
		
		return result

## Create a layer.
# @desc Returns a node corresponding to a type of layer being processed.
#       @a layer is a Dictionary containing data about a layer.
#
#       @a map_data is a Dictionary with information about the whole tilemap that
#       is needed to correctly build the layer. The following keys are recognized:
#
#       * tileset -- A @class TileSet resource used to build the tilemap@br
#       * cell_size -- A Vector2 specifying the size of a tile@br
#       * options -- A list of options inherited from @function build()
func create_layer(layer: Dictionary, map_data: Dictionary) -> int:
	var err := validate_layer(layer)
	
	if err: return err
	
	var tileset: TileSet = map_data.tileset
	var cell_size: Vector2 = map_data.cell_size
	
	var opacity: float = layer.get('opacity', 1.0)
	var visible: bool = layer.get('visible', true)
	var infinite: bool = layer.get('infinite', false)
	var options: Dictionary = map_data.options
	
	match layer.type:
		'tilelayer':
			# Initialize tilemap
			var tilemap := TileMap.new()
			tilemap.cell_size = cell_size
			tilemap.collision_layer = collision_layer
			tilemap.collision_mask = collision_mask
			tilemap.cell_y_sort = true
			tilemap.name = layer.name
			tilemap.modulate = Color(1, 1, 1, opacity)
			tilemap.tile_set = tileset
			
			# Get array of chunks
			var chunks := []
			
			if infinite:
				chunks = layer.chunks
			else:
				chunks = [layer]
			
			# Each chunk has an array of tile IDs
			var count := 0
			for chunk in chunks:
				var chunk_data = chunk.data
				
				# If tile data is encoded in Base64
				if 'encoding' in chunk and chunk.encoding == 'base64':
					if 'compression' in chunk:
						var chunk_size := Vector2(chunk.width, chunk.height)
						chunk_data = decompress_layer(chunk_data, chunk.compression, chunk_size)
						if chunk_data is int: return chunk_data
					else:
						chunk_data = read_base64_layer(chunk_data)
				
				for tile_id in chunk_data:
					var int_id: int = int(tile_id)
					
					# Empty tile
					if not int_id:
						count += 1
						continue
					
					var tile_flags := {
						flipped_y = bool(int_id & FLIPPED_VERTICALLY_FLAG),
						flipped_x = bool(int_id & FLIPPED_HORIZONTALLY_FLAG),
						flipped_d = bool(int_id & FLIPPED_DIAGONALLY_FLAG)
					}
					
					var gid: int = int_id & ~(FLIPPED_VERTICALLY_FLAG | FLIPPED_HORIZONTALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)
					
					var cell := Vector2(
						chunk.x + (count % int(chunk.width)),
						chunk.y + int(count / chunk.width)
					)
					
					tilemap.set_cell(cell.x, cell.y, gid, tile_flags.flipped_x, tile_flags.flipped_y, tile_flags.flipped_d)
					
					count += 1
			
			if options.save_tiled_properties:
				set_tiled_properties_as_meta(tilemap, layer)
			
			if options.custom_properties:
				set_custom_properties(tilemap, layer)
			
			# Finally, add the tilemap to this node
			add_child(tilemap)
		var type:
			print_error("Unknown layer type '%s'." % type)
	
	return OK

func load_image(rel_path: String, source_path: String, options: Dictionary = {}):
	var embed: bool = options.get('embed_internal_images', false)
	var flags: int = options.get('flags', Texture.FLAGS_DEFAULT)
	
	# Invalid extensions
	var ext := rel_path.get_extension().to_lower()
	if ext != "png" and ext != "jpg":
		print_error("Unsupported image format: %s. Use PNG or JPG instead." % [ext])
		return ERR_FILE_UNRECOGNIZED
	
	var total_path := rel_path
	if rel_path.is_rel_path():
		# Turn relative path into a global (OS-specific) path
		total_path = ProjectSettings.globalize_path(source_path.get_base_dir()).plus_file(rel_path)
	# Turn path into one like res:// that Godot will understand
	total_path = ProjectSettings.localize_path(total_path)
	
	# File does not exist = error
	if true:
		var dir := Directory.new()
		if not dir.file_exists(total_path):
			print_error("Image not found: '%s'." % total_path)
			return ERR_FILE_NOT_FOUND
	
	if not total_path.begins_with('res://'):
		embed = true # external image
	
	var image = null
	if embed:
		var temp := Image.new()
		temp.load(total_path) # can load external paths
		
		image = ImageTexture.new()
		(image as ImageTexture).create_from_image(temp, flags)
	else:
		image = ResourceLoader.load(total_path, "ImageTexture")
	
	if image:
		image.set_flags(flags)
	
	return image

## Prints an error.
# @desc Prints @a err with an already-defined prefix in one of two ways depending
#       on where it is called, either in the editor or in a running instance.
static func print_error(err: String) -> void:
	if Engine.editor_hint:
		printerr(ERROR_PREFIX + err)
	else:
		push_error(ERROR_PREFIX + err)

func decode_layer(layer_data: PoolByteArray) -> Array:
	var result := []
	
	for i in range(0, layer_data.size(), 4):
		var num: int = (layer_data[i]) | (layer_data[i + 1] << 8) | (layer_data[i + 2] << 16) | (layer_data[i + 3] << 24)
		result.push_back(num)
	
	return result

func decompress_layer(layer_data: String, compression: String, map_size: Vector2):
	if compression != 'zlib' and compression != 'gzip':
		print_error("Invalid compression '%s', must be zlib or gzip." % compression)
		return ERR_INVALID_PARAMETER
	
	var expected_size: int = int(map_size.x) * int(map_size.y) * 4
	var compression_type := File.COMPRESSION_DEFLATE if compression == 'zlib' else File.COMPRESSION_GZIP
	var data := Marshalls.base64_to_raw(layer_data).decompress(expected_size, compression_type)
	
	return decode_layer(data)

func get_custom_properties(properties: Dictionary, types: Dictionary) -> Dictionary:
	var result := {}
	
	for property in properties:
		var value = null
		
		match (types[property] as String).to_lower():
			'bool':
				value = bool(properties[property])
			'int':
				value = int(properties[property])
			'float':
				value = float(properties[property])
			'color':
				value = Color(properties[property])
			_:
				value = properties[property]
		
		result[property] = value
	
	return result

func read_base64_layer(layer_data: String) -> Array:
	var data := Marshalls.base64_to_raw(layer_data)
	return decode_layer(data)

## Reads a Tiled tilemap file.
# @desc Reads a TMX file pointed to by @a path. It can be either a .tmx file
#       which case it is read as XML) or a JSON file. A dictionary containing
#       information about the tileset is returned, or int upon failure.
#
#       If the returned value is an int, it will be a constant of enum @enum Error.
func read_tilemap_file(path: String):
	if path.get_extension().to_lower() == 'tmx':
		var tmx_to_dict := TiledXMLToDict.new()
		var data = tmx_to_dict.read_tmx(path)
		
		if not data is Dictionary:
			print_error("Error parsing tilemap file '%s'." % path)
		
		return data
	
	var file := File.new()
	
	var content = file.open(path, File.READ)
	if content: return content
	
	content = file.get_as_text()
	file.close()
	
	content = JSON.parse(content)
	if content.error:
		print_error("Error parsing JSON file '%s': %s" % [path, content.error_string])
		return content.error
	
	return content.result

## Reads a Tiled tileset file.
# @desc Reads a TSX file pointed to by @a path. It can either be a .tsx file (in
#       which case it is read as XML) or a JSON file. A dictionary containing
#       information about the tileset is returned, or int upon failure.
#
#       If the returned value is an int, it will be a constant of enum @enum Error.
func read_tileset_file(path: String):
	# Parse the TSX file as XML
	if path.get_extension().to_lower() == 'tsx':
		var tmx_to_dict := TiledXMLToDict.new()
		var data = tmx_to_dict.read_tsx(path)
		
		if not data is Dictionary:
			print_error("Error parsing tileset file '%s'." % path)
		
		return data # either a dict or an integer
	
	var file := File.new()
	
	var content = file.open(path, File.READ)
	if content: return content
	
	content = file.get_as_text()
	file.close()
	
	# Parse the contents of the file as JSON text
	content = JSON.parse(content)
	if content.error:
		print_error("Error parsing JSON: " + content.error_string)
		return content.error
	
	return content.result

func reset_global_members() -> void:
	_tileset_path_to_first_gid = {}
	_loaded_templates = {}

func set_custom_properties(object: Object, tiled_object: Dictionary) -> void:
	if not 'properties' in tiled_object or not 'propertytypes' in tiled_object:
		return
	
	var properties := get_custom_properties(tiled_object.properties, tiled_object.propertytypes)
	
	for property in properties:
		object.set_meta(property, properties[property])

func set_obj_default_params(object: Dictionary) -> void:
	for attr in ['width', 'height', 'rotation', 'x', 'y']:
		if not attr in object:
			object[attr] = 0
	if not 'type' in object: object.type = ''
	if not 'visible' in object: object.visible = true

# For functions with *options* parameter, this sets their defaults.
func set_options_defaults(options: Dictionary, params: Dictionary) -> void:
	var keys := params.keys()
	var defaults := params
	
	for k in keys:
		if not k in options:
			options[k] = defaults[k]

func shape_from_object(object: Dictionary):
	var shape = ERR_INVALID_DATA
	
	set_obj_default_params(object)
	
	if 'polygon' in object or 'polyline' in object:
		pass # TODO: make a polygon or polyline shape
	elif 'ellipse' in object:
		if object.type in ['navigation', 'occluder']:
			print_error("Invalid object type '%s'. Navigation and occluders do not accept ellipse shapes." % object.type)
			return ERR_INVALID_DATA
		
		if not 'width' in object or not 'height' in object:
			print_error("Missing width or height property in ellipse shape")
			return ERR_INVALID_DATA
		
		var w := float(object.width)
		var h := float(object.height)
		
		if w == h:
			shape = CircleShape2D.new()
			shape.radius = w / 2.0
		else:
			shape = CapsuleShape2D.new()
			shape.radius = w / 2.0
			shape.height = h / 2.0
	else:
		if not 'width' in object or not 'height' in object:
			print_error("Missing width or height property in rectangle shape")
			return ERR_INVALID_DATA
		
		var size := Vector2(object.width, object.height)
		
		if object.type in ['navigation', 'occluder']:
			pass # TODO: make navigation and occluder shapes
		else:
			shape = ConvexPolygonShape2D.new()
			var points := PoolVector2Array([
				Vector2(0, 0),
				Vector2(size.x, 0),
				size,
				Vector2(0, size.y)
			])
			shape.set_point_cloud(points)
	
	return shape

func set_tiled_properties_as_meta(object: Object, tiled_object: Dictionary) -> void:
	for property in WHITELIST_PROPERTIES:
		if property in tiled_object:
			object.set_meta(property, tiled_object[property])

func validate_layer(layer: Dictionary) -> int:
	if not 'type' in layer:
		print_error("Missing or invalid layer type property.")
		return ERR_INVALID_DATA
	elif not 'name' in layer:
		print_error("Missing or invalid name type property.")
		return ERR_INVALID_DATA
	
	match layer.type:
		'grouplayer':
			if not 'layers' in layer or not layer.layers is Array:
				print_error("Missing or invalid layer array for group layer.")
				return ERR_INVALID_DATA
		'imagelayer':
			if not 'image' in layer or not layer.image is String:
				print_error("Missing or invalid image path for image layer.")
				return ERR_INVALID_DATA
		'objectgroup':
			if not 'objects' in layer or not layer.objects is Array:
				print_error("Missing or invalid object array for object layer.")
				return ERR_INVALID_DATA
		'tilelayer':
			for f in ['width', 'height', 'x', 'y']:
				if not f in layer or not (layer[f] as String).is_valid_integer():
					print_error("Missing or invalid layer %s property." % f)
					return ERR_INVALID_DATA
			
			if not 'data' in layer:
				if not 'chunks' in layer:
					print_error('Missing data or chunks layer property.')
					return ERR_INVALID_DATA
				elif not layer.chunks is Array:
					print_error('Invalid chunks layer property.')
					return ERR_INVALID_DATA
			elif 'encoding' in layer:
				if layer.encoding == 'base64' and not layer.data is String:
					print_error('Missing or invalid base64 tile layer data.')
					return ERR_INVALID_DATA
				elif layer.encoding != 'base64' and not layer.data is Array:
					print_error('Missing or invalid tile layer data.')
					return ERR_INVALID_DATA
			elif not layer.data is Array:
				print_error('Invalid base64 tile layer data.')
				return ERR_INVALID_DATA
			
			if 'compression' in layer:
				if layer.compression != 'gzip' and layer.compression != 'zlib':
					print_error("Invalid compression '%s'." % layer.compression)
					return ERR_INVALID_DATA
	
	return OK

func validate_tilemap(tilemap: Dictionary) -> int:
	
	
	return OK

## Validate a tileset.
# @desc Returns an integer from the enum @enum Error. @constant OK is returned
#       if the tileset is valid, and @constant ERR_INVALID_DATA otherwise.
func validate_tileset(tileset: Dictionary) -> int:
	for k in ['firstgid', 'tilewidth', 'tileheight', 'tilecount']:
		if not(k in tileset) or not (tileset[k] as String).is_valid_integer():
			print_error("Missing or invalid tileset '%s' property." % k)
			return ERR_INVALID_DATA
	
	if not 'image' in tileset:
		for tile in tileset.tiles:
			if not 'image' in tileset.tiles[tile]:
				print_error("Missing 'image' property in tileset.")
				return ERR_INVALID_DATA
			elif not 'imagewidth' in tileset.tiles[tile] or not str(tileset.tiles[tile].imagewidth).is_valid_integer():
				print_error("Missing or invalid 'imagewidth' property in tileset.")
				return ERR_INVALID_DATA
			elif not 'imageheight' in tileset.tiles[tile] or not str(tileset.tiles[tile].imageheight).is_valid_integer():
				print_error("Missing or invalid 'imageheight' property in tileset.")
				return ERR_INVALID_DATA
	else:
		if not 'imagewidth' in tileset or not str(tileset.imagewidth).is_valid_integer():
			print_error("Missing or invalid 'imagewidth' property in tileset.")
			return ERR_INVALID_DATA
		elif not 'imageheight' in tileset or not str(tileset.imageheight).is_valid_integer():
			print_error("Missing or invalid 'imageheight' property in tileset.")
			return ERR_INVALID_DATA
	
	return OK
