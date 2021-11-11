tool
extends Reference

static func attributes_to_dict(parser: XMLParser) -> Dictionary:
	var data := {}
	
	for i in parser.get_attribute_count():
		var attr := parser.get_attribute_name(i)
		var val = parser.get_attribute_value(i)
		
		if val.is_valid_integer():
			val = int(val)
		elif val.is_valid_float():
			val = float(val)
		elif val == "true":
			val = true
		elif val == "false":
			val = false
		data[attr] = val
	
	return data

func parse_group_layer(parser: XMLParser, infinite: bool):
	var err := OK
	var data := attributes_to_dict(parser)
	
	data = {
		type = 'group',
		layers = []
	}
	
	if not parser.is_empty():
		err = parser.read()
		
		while err == OK:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name().to_lower() == "group":
					break
			elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
				match parser.get_node_name():
					'group':
						var layer = parse_group_layer(parser, infinite)
						
						if not(layer is Dictionary):
							print_error("Error parsing TMX file: Invalid group layer data (around line %d)" % [parser.get_current_line()])
							return ERR_INVALID_DATA
							
						(data.layers as Array).push_back(layer)
					'imagelayer':
						var layer = parse_image_layer(parser)
						
						if not(layer is Dictionary):
							print_error("Error parsing TMX file: Invalid image layer data (around line %d)" % [parser.get_current_line()])
							return ERR_INVALID_DATA
						
						(data.layers as Array).push_back(layer)
					'layer':
						var layer = parse_tile_layer(parser, infinite)
						
						if not(layer is Dictionary):
							print_error("Error parsing TMX file: Invalid tile layer data (around line %d)" % [parser.get_current_line()])
							return ERR_INVALID_DATA
							
						(data.layers as Array).push_back(layer)
					'objectgroup':
						var layer = parse_object_layer(parser)
						
						if not(layer is Dictionary):
							print_error("Error parsing TMX file: Invalid object layer data (around line %d)" % parser.get_current_line())
							return ERR_INVALID_DATA
						
						(data.layers as Array).push_back(layer)
					'properties':
						var prop_data = parse_properties(parser)
						
						if not (prop_data is Dictionary):
							return prop_data
							
						data.properties = prop_data.properties
						data.propertytypes = prop_data.propertytypes
			
			err = parser.read()
	
	return data

func parse_image_layer(parser: XMLParser):
	var err := OK
	var data := attributes_to_dict(parser)
	
	data.type = 'imagelayer'
	data.image = ''
	
	if not parser.is_empty():
		err = parser.read()
		
		while err == OK:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name() == 'imagelayer':
					break
			elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
				match parser.get_node_name():
					'image':
						var attr = attributes_to_dict(parser)
						
						if not('source' in attr):
							print_error("Error loading image tag: No source attribute found (around line %d)" % parser.get_current_line())
							return ERR_INVALID_DATA
						
						data.image = attr.source
					'properties':
						var prop_data = parse_properties(parser)
						
						if not (prop_data is Dictionary):
							return prop_data
						
						data["properties"] = prop_data.properties
						data["propertytypes"] = prop_data.propertytypes
				
			err = parser.read()
	
	return data

func parse_object(parser: XMLParser):
	var data := attributes_to_dict(parser)
	var err := OK

	if not parser.is_empty():
		err = parser.read()

		while err == OK:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name() == "object":
					break
			elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
				match parser.get_node_name():
					'ellipse':
						data.ellipse = true
					'point':
						data.point = true
					'properties':
						var prop_data = parse_properties(parser)
						data["properties"] = prop_data.properties
						data["propertytypes"] = prop_data.propertytypes
					var node_name:
						if node_name == 'polygon' or node_name == 'polyline':
							var points_raw := parser.get_named_attribute_value('points').split(' ', false)
							var points := []

							for p in points_raw:
								var temp := (p as String).split_floats(',')
								points.push_back({
									x = temp[0],
									y = temp[1]
								})

							data[node_name] = points

			err = parser.read()
	
	return data

func parse_object_layer(parser: XMLParser):
	var data := attributes_to_dict(parser)
	var err := OK
	
	data.objects = []
	data.type = 'objectgroup'
	
	if not parser.is_empty():
		err = parser.read()
		
		while err == OK:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name() == "objectgroup":
					break
			elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
				match parser.get_node_name():
					'object':
						(data.objects as Array).push_back(parse_object(parser))
					'properties':
						var prop_data = parse_properties(parser)
						
						if not(prop_data is Dictionary):
							return prop_data # error happened
						
						data.properties = prop_data.properties
						data.propertytypes = prop_data.propertytypes

			err = parser.read()
	
	return data

static func parse_properties(parser: XMLParser):
	var data := {
		'properties': {},
		'propertytypes': {}
	}
	var err := parser.read()
	
	while err == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == 'properties':
				break
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
			if parser.get_node_name() == 'property':
				var prop_data := attributes_to_dict(parser)
				if not(prop_data.has('name') and prop_data.has('value')):
					print_error("Missing information in custom properties (around line %d)." % parser.get_current_line())
					return ERR_INVALID_DATA
				
				data.properties[prop_data.name] = prop_data.value
				
				if prop_data.has('type'):
					data.propertytypes[prop_data.name] = prop_data.type
				else:
					data.propertytypes[prop_data.name] = 'string'
		
		err = parser.read()
	
	return data

func parse_tile_data(parser: XMLParser):
	var data := {}
	var err := parser.read()
	var obj_group := {}
	
	while err == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == 'tile':
				return data
			elif parser.get_node_name() == 'objectgroup':
				data.objectgroup = obj_group
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
			match parser.get_node_name():
				'image':
					var attr = attributes_to_dict(parser)
					if not('source' in attr):
						print_error("Error loading image tag: No source attribute found (around line %d)" % parser.get_current_line())
						return ERR_INVALID_DATA
					data.image = attr.source
					data.imagewidth = attr.width
					data.imageheight = attr.height
				'object':
					if not('objects' in obj_group):
						obj_group.objects = []
					
					var obj = parse_object(parser)
					if not(obj is Dictionary):
						return obj
					
					(obj_group.objects as Array).push_back(obj)
				'objectgroup':
					obj_group = attributes_to_dict(parser)
					
					for attr in ['width', 'height', 'offsetx', 'offsety']:
						if not(attr in obj_group):
							data[attr] = 0
					
					if not('opacity' in data):
						data.opacity = 1.0
					if not('visible' in data):
						data.visible = true
					if parser.is_empty():
						data.objectgroup = obj_group
				'properties':
					var prop_data = parse_properties(parser)
					data.properties = prop_data.properties
					data.propertytypes = prop_data.propertytypes
		
		err = parser.read()

func parse_tile_layer(parser: XMLParser, infinite: bool):
	var data := attributes_to_dict(parser)
	var err := OK
	
	# Set attributes
	data.type = "tilelayer"
	
	if not "x" in data:
		data.x = 0
	if not "y" in data:
		data.y = 0
	
	if infinite:
		data.chunks = []
	else:
		data.data = []
	
	var encoding = ""
	var current_chunk = null
	
	if not parser.is_empty():
		err = parser.read()
		while err == OK:
			if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name() == 'layer':
					break
				elif parser.get_node_name() == 'chunk':
					(data.chunks as Array).push_back(current_chunk)
					current_chunk = null
			elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
				match parser.get_node_name():
					'chunk':
						current_chunk = attributes_to_dict(parser)
						current_chunk.data = []
						
						if encoding != '':
							err = parser.read()
							
							if err: return err
							
							if encoding != 'csv':
								current_chunk.data = parser.get_node_data().strip_edges()
							else:
								var csv := parser.get_node_data().split(',', false)
								
								for v in csv:
									(current_chunk.data as Array).push_back(int(v.strip_edges()))
					'data':
						var attr = attributes_to_dict(parser)
						
						if 'compression' in attr:
							data.compression = attr.compression
						
						if 'encoding' in attr:
							encoding = attr.encoding
							
							if attr.encoding != 'csv':
								data.encoding = attr.encoding
							
							if not infinite:
								err = parser.read()
								
								if err:
									return err
								
								if encoding != 'csv':
									data.data = parser.get_node_data().strip_edges()
								else:
									var csv := parser.get_node_data().split(',', false)
									
									for v in csv:
										(data.data as Array).push_back(int(v.strip_edges()))
					'properties':
						var prop_data = parse_properties(parser)
						
						if not(prop_data is Dictionary):
							return prop_data
						
						data.properties = prop_data.properties
						data.propertytypes = prop_data.propertytypes
					'tile':
						var gid := int(parser.get_named_attribute_value_safe('gid'))
						
						if infinite:
							(current_chunk.data as Array).push_back(gid)
						else:
							(data.data as Array).push_back(gid)
			
			err = parser.read()
	
	return data

func parse_tileset(parser: XMLParser):
	var err := OK
	var data := attributes_to_dict(parser)
	data.tiles = {}
	
	err = parser.read()
	
	while err == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == 'tileset':
				break
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
			match parser.get_node_name():
				'tile':
					var attr := attributes_to_dict(parser)
					var tile_data = parse_tile_data(parser)
					if not(tile_data is Dictionary):
						# Error happened
						return tile_data
					if 'properties' in tile_data and 'propertytypes' in tile_data:
						if not('tileproperties' in data):
							data.tileproperties = {}
							data.tilepropertytypes = {}
						data.tileproperties[str(attr.id)] = tile_data.properties
						data.tilepropertytypes[str(attr.id)] = tile_data.tilepropertytypes
						tile_data.erase('tileproperties')
						tile_data.erase('tilepropertytypes')
					data.tiles[str(attr.id)] = tile_data
				'image':
					var attr = attributes_to_dict(parser)
					if not('source' in attr):
						print_error("Error loading image tag: No source attribute found (around line %d)" % parser.get_current_line())
						return ERR_INVALID_DATA
					data.image = attr.source
					if 'width' in attr:
						data.imagewidth = attr.width
					if 'height' in attr:
						data.imageheight = attr.height
				'property':
					var prop_data = parse_properties(parser)
					if not(prop_data is Dictionary):
						# Error happened
						return prop_data

					data.properties = prop_data.properties
					data.propertytypes = prop_data.propertytypes
		
		err = parser.read()
	
	return data

static func print_error(err: String) -> void:
	if Engine.editor_hint:
		printerr(err)
	else:
		push_error(err)
		breakpoint

func read_tmx(path: String):
	var parser := XMLParser.new()
	var err: int = parser.open(path)
	if err:
		print_error("Failed to open TMX file '%s'." % path)
		return err
	
	# Skip to the first element
	while parser.get_node_type() != XMLParser.NODE_ELEMENT:
		err = parser.read()
		if err:
			print_error("Error parsing TMX file '%s' (around line %d)." % [path, parser.get_current_line()])
			return err
	
	# First element-node must be 'map'
	if parser.get_node_name().to_lower() != 'map':
		print_error("Error parsing TMX file '%s': no 'map' element found." % path)
		return ERR_INVALID_DATA
	
	# Get dictionary of attributes
	var data = attributes_to_dict(parser)
	if not "infinite" in data:
		data.infinite = false
	data.type = "map"
	data.tilesets = []
	data.layers = []
	
	# Read up to the </map>
	err = parser.read()
	if err:
		print_error("Error parsing TMX file '%s' (around line %d)." % [path, parser.get_current_line()])
		return err
	
	while err == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == 'map':
				break # </map>, done processing
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT:
			# Process each element
			match parser.get_node_name():
				'group':
					var layer = parse_group_layer(parser, data.infinite)
					
					if not(layer is Dictionary):
						print_error("Error parsing TMX file '%s': Invalid group layer data (around line %d)" % [path, parser.get_current_line()])
						return ERR_INVALID_DATA
					
					(data.layers as Array).push_back(layer)
				'layer':
					var layer = parse_tile_layer(parser, data.infinite)
					
					if not(layer is Dictionary):
						print_error("Error parsing TMX file '%s': Invalid tile layer data (around line %d)" % [path, parser.get_current_line()])
						return ERR_INVALID_DATA
					
					(data.layers as Array).push_back(layer)
				'objectgroup':
					var layer = parse_object_layer(parser)
					
					if not(layer is Dictionary):
						print_error("Error parsing TMX file '%s': Invalid object layer data (around line %d)" % [path, parser.get_current_line()])
						return ERR_INVALID_DATA
					
					(data.layers as Array).push_back(layer)
				'properties':
					var prop_data = parse_properties(parser)
					
					if not(prop_data is Dictionary):
						return prop_data

					data.properties = prop_data.properties
					data.propertytypes = prop_data.propertytypes
				'tileset':
					if not parser.is_empty():
						var tileset_data = parse_tileset(parser)
						if not(tileset_data is Dictionary):
							return err # error happened, return what was finished so far
						(data.tilesets as Array).push_back(tileset_data)
					else:
						# External tileset
						var tileset_data := attributes_to_dict(parser)
						if not('source' in tileset_data):
							print_error("Error parsing '%s': No tileset found (around line %d)" % [path, parser.get_current_line()])
							return ERR_INVALID_DATA
						(data.tilesets as Array).push_back(tileset_data)
		
		err = parser.read()
	
	return data

func read_tsx(path: String):
	var parser := XMLParser.new()
	var err: int = parser.open(path)
	if err:
		print_error("Failed to open TSX file '%s'." % path)
		return err
	
	# Skip to the first element
	while parser.get_node_type() != XMLParser.NODE_ELEMENT:
		err = parser.read()
		if err:
			print_error("Error parsing TSX file '%s' (around line %d)." % [path, parser.get_current_line()])
			return err
	
	if parser.get_node_name().to_lower() != 'tileset':
		print_error("Error parsing TMX file '%s': no 'tileset' element found." % path)
		return ERR_INVALID_DATA
	
	return parse_tileset(parser)
