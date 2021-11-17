## Loader of Tiled map files.
# @name TiledMapLoader
tool
extends Node2D

# 'Set Tiled Properties,Set Custom Properties,Clip UV'
enum {
	SET_TILED_PROPERTIES = 0x01,
	SET_CUSTOM_PROPERTIES = 0x02,
	CLIP_UV = 0x04
}

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

## Tilemap properties as bitmask
# @type int
var tilemap_properties := 0

var correct_map := false

const ERROR_PREFIX := "Tiled Map Loader: "

## Horizontal flip bit (@link{http://doc.mapeditor.org/reference/tmx-map-format/#tile-flipping}{more info})
const FLIPPED_HORIZONTALLY_FLAG: int = 0x80000000

## Horizontal flip bit (@link{http://doc.mapeditor.org/reference/tmx-map-format/#tile-flipping}{more info})
const FLIPPED_VERTICALLY_FLAG: int = 0x40000000

## Diagonal flip bit (@link{http://doc.mapeditor.org/reference/tmx-map-format/#tile-flipping})
const FLIPPED_DIAGONALLY_FLAG: int = 0x20000000

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
		'options/tilemap_properties':
			return tilemap_properties

func _set(property: String, value) -> bool:
	match property:
		'tilemap':
			tilemap = value
		'collision_layer':
			collision_layer = value
		'collision_mask':
			collision_mask = value
		'options/tilemap_properties':
			tilemap_properties = value
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
			name = 'collision_mask',
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT,
			hint = PROPERTY_HINT_LAYERS_2D_PHYSICS
		},
		{
			name = 'options/tilemap_properties',
			type = TYPE_INT,
			usage = PROPERTY_USAGE_DEFAULT,
			hint = PROPERTY_HINT_FLAGS,
			hint_string = 'Set Tiled Properties,Set Custom Properties,Clip UV'
		}
	]

func _object_sorter(first: Dictionary, second: Dictionary) -> bool:
	if first.y == second.y:
		return first.id < second.id
	return first.y < second.y

static func _despace(text: String) -> String:
	return text.replace(' ', '')

static func _convert_value(value: String, type: String):
	match type:
		'int':
			return int(value)
		'float':
			return float(value)
		'bool':
			return bool(value)
		'color':
			return Color(value)
	
	return value

func _fix_json_properties(data):
	var data_type : int = typeof(data)
	
	if data_type == TYPE_ARRAY:
		for element in data:
			_fix_json_properties(element)
	elif data_type == TYPE_DICTIONARY:
		for k in data:
			if k == 'properties':
				var properties : Dictionary
				var propertytypes : Dictionary
				
				# data.properties is array
				# property = {name = ..., type = ..., value = ...}
				for property in data.properties:
					# Want properties = { "id": 1 , "name": "name" , ... }
					var prop_name : String = property.name
					var prop_value = _convert_value(property.value, property.type)
					properties[prop_name] = prop_value
					propertytypes[prop_name] = property.type
				
				data.properties = properties
				data.propertytypes = propertytypes
			else:
				_fix_json_properties(data[k])

static func apply_template(object, template_const):
	for k in template_const:
		if typeof(template_const[k]) == TYPE_DICTIONARY:
			if not object.has(k):
				object[k] = {}
			apply_template(object[k], template_const[k])
		elif not object.has(k):
			object[k] = template_const[k]

## Builds a tilemap and adds it as a child.
# @desc ...
#
#       @a options is a dictionary that shall have the following keys. Note: format is
#       @code{name (type) -- description <default>}.
#
#       * save_tiled_properties (bool) -- If true, set tiled properties as meta <false> @br
#       * custom_properties (bool) -- If true, set custom properties as meta <false>@br
#       * clip_uv (bool) -- If true, clips the tilemap's UV <false>
func build(source_path: String, options: Dictionary) -> int:
	var err := OK
	reset_global_members()
	
	set_options_defaults(options, {
		save_tiled_properties = false,
		custom_properties = false,
		clip_uv = false
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
	
	# Offset of each tile
	var cell_offset := Vector2()
	
	# Size of each tile
	var cell_size := Vector2(int(map.tilewidth), int(map.tileheight))
	
	# Offset of the entire map
	var map_pos_offset := Vector2()
	
	# Half offset flag for TileMap
	var map_offset := TileMap.HALF_OFFSET_DISABLED
	
	# Map mode
	var map_mode : int = TileMap.MODE_SQUARE
	if 'orientation' in map:
		match map.orientation:
			'isometric':
				map_mode = TileMap.MODE_ISOMETRIC
			'staggered':
				# isometric staggered
				map_pos_offset.y -= cell_size.y / 2
				match map.staggeraxis:
					'x':
						map_offset = TileMap.HALF_OFFSET_Y
						cell_size.x /= 2
						if map.staggerindex == 'even':
							cell_offset.x += 1
							map_pos_offset.x -= cell_size.x
					'y':
						map_offset = TileMap.HALF_OFFSET_X
						cell_size.y /= 2
						if map.staggerindex == 'even':
							cell_offset.y += 1
							map_pos_offset.y -= cell_size.y
			'hexagonal':
				# hexagonal staggered
				match map.staggeraxis:
					'x':
						map_offset = TileMap.HALF_OFFSET_Y
						cell_size.x = int((cell_size.x + map.hexsidelength) / 2)
						if map.staggerindex == 'even':
							cell_offset.x += 1
							map_pos_offset.x -= cell_size.x
					'y':
						map_offset = TileMap.HALF_OFFSET_X
						cell_size.x = int((cell_size.y + map.hexsidelength) / 2)
						if map.staggerindex == 'even':
							cell_offset.y += 1
							map_pos_offset.y -= cell_size.y
	
	# Global map data
	var map_data := {
		tileset = tileset,
		cell_size = cell_size,
		options = options,
		infinite = map.infinite,
		map_offset = map_offset,
		map_pos_offset = map_pos_offset,
		cell_offset = cell_offset,
		source_path = source_path
	}
	
	for layer in map.layers:
		err = create_layer(layer, map_data)
		if err: return err
	
	return OK

## Builds a tilemap using the properties defined in this class.
func build_auto() -> int:
	var options := {
		save_tiled_properties = bool(tilemap_properties & SET_TILED_PROPERTIES),
		custom_properties = bool(tilemap_properties & SET_CUSTOM_PROPERTIES),
		clip_uv = bool(tilemap_properties & CLIP_UV)
	}
	
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
		var ts = tileset
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
					if not shape is Object:
						return shape # error happened
					
					var offset := Vector2(object.x, object.y)
					var apply_offset: bool = options.get('apply_offset', false)
					
					if apply_offset:
						offset += result.tile_get_texture_offset(gid)
					
#					if 'width' in object and 'height' in object:
#						offset += Vector2(float(object.width) / 2.0, float(object.height) / 2.0)
					
					match object.type:
						'navigation':
							result.tile_set_navigation_polygon(gid, shape)
							result.tile_set_navigation_polygon_offset(gid, offset)
						'occluder':
							result.tile_set_light_occluder(gid, shape)
							result.tile_set_occluder_offset(gid, offset)
						_:
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

func chunks_topleft(layer: Dictionary):
	var result := Vector2()
	
	for chunk in layer.chunks:
		result.x = min(result.x, chunk.x)
		result.y = min(result.y, chunk.y)
	
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
	
	var opacity: float = layer.get('opacity', 1.0)
	var visible: bool = layer.get('visible', true)
	
	var tileset: TileSet = map_data.tileset
	var cell_size: Vector2 = map_data.cell_size
	var infinite: bool = map_data.infinite
	var options: Dictionary = map_data.options
	var cell_offset : Vector2 = map_data.cell_offset
	
	match layer.type:
		'tilelayer':
			# Initialize tilemap
			var tilemap := TileMap.new()
			tilemap.cell_size = cell_size
			tilemap.collision_layer = collision_layer
			tilemap.collision_mask = collision_mask
			tilemap.cell_y_sort = true
			tilemap.name = _despace(layer.name)
			tilemap.modulate = Color(1, 1, 1, opacity)
			tilemap.tile_set = tileset
			tilemap.cell_tile_origin = TileMap.TILE_ORIGIN_BOTTOM_LEFT
			tilemap.cell_half_offset = map_data.map_offset
			tilemap.cell_clip_uv = options.clip_uv
			
			# Layer offset
			var offset := Vector2()
			if 'startx' in layer:
				offset.x = layer.startx
			if 'starty' in layer:
				offset.y = layer.starty
			
			tilemap.position = offset + map_data.map_pos_offset
			#tilemap.position = Vector2()
			
			var chunk_offset := Vector2()
			var chunk_origin := Vector2()
			
			# Get array of chunks
			var chunks := []
			
			if infinite:
				chunks = layer.chunks
				chunk_origin = chunks_topleft(layer)
			else:
				chunks = [layer]
			
			# Each chunk has an array of tile IDs
			var count := 0
			for chunk in chunks:
				err = validate_chunk(chunk)
				if err: return err
				
				var chunk_data = chunk.data
				
				chunk_offset = Vector2(chunk.x, chunk.y) - chunk_origin
				
				# If tile data is encoded in Base64
				if 'encoding' in layer and layer.encoding == 'base64':
					# Data is compressed
					if 'compression' in layer:
						var chunk_size := Vector2(chunk.width, chunk.height)
						chunk_data = decompress_layer(chunk_data, layer.compression, chunk_size)
						if chunk_data is int: return chunk_data
					else:
						chunk_data = read_base64_layer(chunk_data)
				
				count = 0
				
				for tile_id in chunk_data:
					var int_id: int = int(tile_id)
					
					# Empty tile
					if int_id == 0:
						count += 1
						continue
					
					# Isolate the tile flipping flags
					var tile_flags := {
						flipped_y = bool(int_id & FLIPPED_VERTICALLY_FLAG),
						flipped_x = bool(int_id & FLIPPED_HORIZONTALLY_FLAG),
						flipped_d = bool(int_id & FLIPPED_DIAGONALLY_FLAG)
					}
					
					var gid: int = int_id & ~(FLIPPED_VERTICALLY_FLAG | FLIPPED_HORIZONTALLY_FLAG | FLIPPED_DIAGONALLY_FLAG)
					
					# In the case that any chunk has a negative offset, all tiles in the level need to be shifted right to push that chunk to the left edge of the level. Because if a tile cell index ends up negative, it gets clipped out of existence.
					
					var cell_x : int = cell_offset.x + (count % int(chunk.width)) + chunk_offset.x
					var cell_y : int = cell_offset.y + int(count / chunk.width) + chunk_offset.y
					
					tilemap.set_cell(cell_x, cell_y, gid, tile_flags.flipped_x, tile_flags.flipped_y, tile_flags.flipped_d)
					
					count += 1
			
			if options.save_tiled_properties:
				set_tiled_properties_as_meta(tilemap, layer)
			
			if options.custom_properties:
				set_custom_properties(tilemap, layer)
			
			# Finally, add the tilemap to this node
			add_child(tilemap)
			tilemap.owner = self
		'objectgroup':
			var object_layer := Node2D.new()
			
			if options.save_tiled_properties:
				set_tiled_properties_as_meta(object_layer, layer)
			
			if options.custom_properties:
				set_custom_properties(object_layer, layer)
			
			object_layer.modulate = Color(1, 1, 1, opacity)
			object_layer.visible = visible
			add_child(object_layer)
			object_layer.owner = self
			
			if 'name' in layer and not str(layer.name).empty():
				object_layer.name = _despace(str(layer.name))
			
			if not 'draworder' in layer or layer.draworder == 'topdown':
				(layer.objects as Array).sort_custom(self, '_object_sorter')
			
			for object in layer.objects:
				if 'template' in object:
					var template_file = object.template
					var template_data_const = get_template(remove_filename_from_path(map_data.source_path) + template_file)
					
					if not template_data_const is Dictionary:
						print_error("Error getting template for object with id %s" % map_data.id)
						continue
					
					# Overwrite template data with current object data
					apply_template(object, template_data_const)
					
					set_obj_default_params(object)
				
				if 'point' in object and object.point:
					var point := Position2D.new()
					if not 'x' in object or not 'y' in object:
						print_error("Missing coordinates for point in object layer.")
						continue
					
					point.position = Vector2(float(object.x), float(object.y))
					point.visible = object.visible
					
					# Give a name to the point
					var _name : String = object.get('name', '')
					if _name.empty():
						_name = str(object.get('id', ''))
					if not _name.empty(): point.name = _despace(_name)
					
					object_layer.add_child(point, !_name.empty())
					point.owner = object_layer
					
					if options.save_tiled_properties:
						set_tiled_properties_as_meta(point, object)
					
					if options.custom_properties:
						set_custom_properties(point, object)
		var type:
			print_error("Unknown layer type '%s'." % type)
	
	return OK

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

# TODO: implement get_first_gid_from_tileset_path

static func get_filename_from_path(path: String) -> String:
	var substrings := path.split('/')
	var file : String = substrings[-1]
	return file

func get_template(path: String):
	if not _loaded_templates.has(path):
		if path.get_extension().nocasecmp_to('tsx'):
			var parser := XMLParser.new()
			var err: int = parser.open(path)
			if err:
				#print_error("Failed to open TX file '%s'." % path)
				return err
			
			var template = parse_template(parser, path)
			if not template is Dictionary:
				print_error("Error parsing TX file '%s'." % path)
				return false
			
			_loaded_templates[path] = template
		else:
			# JSON
			var file := File.new()
			
			var err := file.open(path, File.READ)
			if err: return err
			
			var content
			
			var result := JSON.parse(file.get_as_text())
			file.close()
			if result.error:
				print_error("Error parsing JSON template file '%s': %s" % [path, result.error_string])
				return result.error
			else:
				# Get dictionary from parser
				content = content.result
				if not content is Dictionary:
					print_error("Error parsing JSON template file '%s': JSON object not a dictionary." % [path])
					return ERR_INVALID_DATA
			
			var object : Dictionary = content.object
			if object.has('gid') and object.has('tileset'):
				pass
				# TODO: get first gid from embedded tileset
			
			if object.has('properties'):
				var properties : Dictionary
				var propertytypes : Dictionary
				
				# object.properties is array
				# property = {name = ..., type = ..., value = ...}
				for property in object.properties:
					# Want properties = { "id": 1 , "name": "name" , ... }
					var prop_name : String = property.name
					var prop_value = _convert_value(property.value, property.type)
					properties[prop_name] = prop_value
			
			_loaded_templates[path] = object
	
	var dict : Dictionary = _loaded_templates[path]
	var dictCopy : Dictionary = {} # = dict.duplicate(false)
	
	for k in dict:
		dictCopy[k] = dict[k]
	
	return dictCopy

func is_convex(vertices: PoolVector2Array):
	var size := vertices.size()
	
	if size <= 3: return true
	
	var cp = 0
	for i in range(0, size + 2):
		var p1: Vector2 = vertices[i % size]
		var p2: Vector2 = vertices[(i + 1) % size]
		var p3: Vector2 = vertices[(i + 2) % size]
		
		var prev_cp = cp
		cp = (p2.x - p1.x) * (p3.y - p2.y) - (p2.y - p1.y) * (p3.x - p2.x)
		
		if i > 0 and sign(cp) != sign(prev_cp):
			return false
	
	return true

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

func parse_template(parser: XMLParser, path: String) -> Dictionary:
	var err := OK
	var data := {id = 0}
	var tileset_gid_increment := 0
	
	err = parser.read()
	while err == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == 'template':
				break
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
			assert(parser.get_node_name() != 'tileset', "'tileset' currently not supported in template")
			
			match parser.get_node_name():
				'tileset':
					pass # TODO: implement tileset in template
				'object':
					var object : Dictionary = TiledXMLToDict.parse_object(parser)
					for k in object:
						data[k] = object[k]
		
		err = parser.read()
	
	if data.has('gid') and tileset_gid_increment:
		data.gid += tileset_gid_increment
	
	return data

## Prints an error.
# @desc Prints @a err with an already-defined prefix in one of two ways depending
#       on where it is called, either in the editor or in a running instance.
static func print_error(err: String) -> void:
	if Engine.editor_hint:
		printerr(ERROR_PREFIX + err)
	else:
		push_error(ERROR_PREFIX + err)

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
	
	_fix_json_properties(content.result)
	
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

static func remove_filename_from_path(path: String) -> String:
	var file_name := get_filename_from_path(path)
	var string_size : int = path.length() - file_name.length()
	var file_path : String = path.substr(0, string_size)
	return file_path

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

func set_tiled_properties_as_meta(object: Object, tiled_object: Dictionary) -> void:
	for property in WHITELIST_PROPERTIES:
		if property in tiled_object:
			object.set_meta(property, tiled_object[property])

func shape_from_object(object: Dictionary):
	var shape = ERR_INVALID_DATA

	set_obj_default_params(object)

	if 'polygon' in object or 'polyline' in object:
		var vertices := PoolVector2Array()
		
		if 'polygon' in object:
			for point in object.polygon:
				vertices.push_back(Vector2(float(point.x), float(point.y)))
		elif 'polyline' in object:
			for point in object.polyline:
				vertices.push_back(Vector2(float(point.x), float(point.y)))
		
		match object.type:
			'navigation':
				shape = NavigationPolygon.new()
				shape.add_outline(vertices)
				shape.make_polygons_from_outlines()
			'occluder':
				shape = OccluderPolygon2D.new()
				shape.polygon = vertices
				shape.closed = 'polygon' in object
			_:
				var temp = is_convex(vertices)
				
				if is_convex(vertices):
					shape = ConvexPolygonShape2D.new()
					shape.set_point_cloud(vertices)
				else:
					shape = ConcavePolygonShape2D.new()
					var segments := [vertices[0]]
					for i in range(1, vertices.size()):
						segments.push_back(vertices[i])
						segments.push_back(vertices[i])
					segments.push_back(vertices[0])
					shape.segments = PoolVector2Array(segments)
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
			var vertices := PoolVector2Array([
				Vector2(),
				Vector2(size.x, 0),
				size,
				Vector2(0, size.y)
			])
			
			if object.type == 'navigation':
				shape = NavigationPolygon.new()
				shape.set_vertices(vertices)
				shape.add_outline(vertices)
				shape.make_polygons_from_outlines()
			else:
				shape = OccluderPolygon2D.new()
				shape.polygon = vertices
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

func validate_chunk(chunk: Dictionary) -> int:
	if not 'data' in chunk:
		print_error('Missing data chunk.')
		return ERR_INVALID_DATA
	
	for attr in ['x', 'y']:
		if not attr in chunk or not str(chunk[attr]).is_valid_integer():
			print_error("Missing or invalid chunk %s offset." % attr)
			return ERR_INVALID_DATA
	
	for attr in ['width', 'height']:
		if not attr in chunk or not str(chunk[attr]).is_valid_integer() or int(chunk[attr]) <= 0:
			print_error("Missing or invalid chunk %s." % attr)
			return ERR_INVALID_DATA
	
	return OK

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
	for attr in ['version', 'tiledversion']:
		if not attr in tilemap or int(tilemap[attr]) != 1:
			print_error("Missing or invalid '%s' property in tilemap." % attr)
			return ERR_INVALID_DATA
	
	for attr in ['width', 'height', 'tilewidth', 'tileheight', 'nextlayerid', 'nextobjectid']:
		if not attr in tilemap or not (tilemap[attr] as String).is_valid_integer():
			print_error("Missing or invalid '%s' property in tilemap." % attr)
			return ERR_INVALID_DATA
	
	if not 'type' in tilemap or tilemap.type != 'map':
		print_error("Missing or invalid 'type' property in tilemap.")
		return ERR_INVALID_DATA
	
	if not 'infinite' in tilemap:
		print_error("Missing 'infinite' property in tilemap.")
		return ERR_INVALID_DATA
	
	if not 'orientation' in tilemap or not tilemap.orientation in ['orthogonal', 'isometric', 'staggered', 'hexagonal']:
		print_error("Missing or invalid 'orientation' property in tilemap.")
		return ERR_INVALID_DATA
	
	if not 'layers' in tilemap or typeof(tilemap.layers) != TYPE_ARRAY:
		print_error("Missing or invalid 'layers' property in tilemap.")
		return ERR_INVALID_DATA
	
	if not 'tilesets' in tilemap or typeof(tilemap.tilesets) != TYPE_ARRAY:
		print_error("Missing or invalid 'tilesets' property in tilemap.")
		return ERR_INVALID_DATA
	
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
