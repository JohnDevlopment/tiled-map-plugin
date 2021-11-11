extends Control

const StringCommand : Reference = preload('res://addons/debug_console/StringCommand.gd')
const ErrorInfo : Reference = preload('res://addons/debug_console/ErrorInfo.gd')

signal console_destroyed
signal console_command(code, args)

export(Script) var command_script

export(Array, NodePath) var remote_nodes

onready var input_field = $VBoxContainer/InputField
onready var output_box = $VBoxContainer/HBoxContainer/Output
onready var command_handler = $CommandHandler

const _builtin_commands: = [
	[ "/help",  [],   [] ],
	[ "/print", [-1], ["value"] ],
	[ "/test",  [],   [] ],
	[ "/types", [],   [] ],
	[ "/exit", [], [] ]
]

var command_list: = []
var active: = false

func _ready():
	if not command_script:
		push_error("'command_script' property is null")
		return
	
	command_handler.set_script(command_script)
	
	if not command_handler.get("valid_commands"):
		push_error("no 'valid_commands' array defined in command script")
		queue_free()
		return
	elif typeof(command_handler.get("valid_commands")) != TYPE_ARRAY:
		push_error("'valid_commands' not an array")
		queue_free()
		return
	
	command_handler.remote_nodes = remote_nodes
	
	_init_command_map()
	output_box.add_keyword_color("Error", Color("#ff0000"))
	
	for type in ["variant", "bool", "float", "int", "nil"]:
		output_box.add_keyword_color(type, Color("#8EA2FF"))
	output_box.add_keyword_color("vector2", Color("#43E44A"))
	set_process(false)

func activate():
	History.current_index = History.history.size()
	visible = true
	set_process(true)
	get_tree().paused = true
	input_field.grab_focus()
	active = true

func deactivate():
	visible = false
	input_field.release_focus()
	set_process(false)
	get_tree().paused = false
	active = false
	emit_signal("console_destroyed")

func goto_history_line(offset: int):
	History.current_index = int( clamp(History.current_index + offset, 0,
	History.history.size()) )
	
	if not History.history.empty():
		input_field.text = History.get_history_line()
		input_field.call_deferred("set_cursor_position", 9999)
		input_field.grab_focus()

# Outputs the text string to the multiline text window. If the text consists
# of a string in the format of "@xxxxxx:", where x is any lowercase letter,
# then a special formatted error message is produced.
# List:
#   @argcount:X:Y -- output: "Error: expected X parameters but only got Y"
#      A generic parameter count message. May be removed since StringCommand
#      automatically checks parameter count and prints this message.
#   @arrayneed:P:C -- output: "Error: '%P' expects C values"
#      Use this when a parameter is an array and it isn't provided the right
#      amount of values.
#   @error:MSG -- output: "Error: MSG"
#      A generic error message.
func output_text(text: String) -> void:
	if not text:
		text = " "
	else:
		text = _parse_error_string(text)
	output_box.text = str(output_box.text, "\n", text)

func process_command(text: String) -> void:
	var words = text.split(" ", false)
	words = Array(words)
	
	if words.size() == 0: return
	
	var command_name: String = words.pop_front()
	
	if command_name.begins_with("/"):
		_process_builtin_command(command_name, words)
		return
	
	var idx: int = -1
	var command: StringCommand
	
	for i in command_list.size():
		command = command_list[i]
		if command.command_name == command_name:
			idx = i
			break
	
	if idx >= 0:
		var parsed_args = command.parse_args(words)
		
		if (parsed_args is ErrorInfo):
			output_text("Error: " + parsed_args.info)
			return
		
		output_text(command_handler.callv(command.command_name, parsed_args))
		return

	output_text("Error: command %s does not exist" % command_name)

func _parse_error_string(s: String):
	if s == "": return
	var words: Array = s.split(":", false)
	
	match (words.pop_front() as String):
		"@argcount":
			s = "Error: expected {0} arguments but got {1}"
			s = s.format([words[0], words[1]])
		"@arrayneed":
			s = "array '{0}' requires {1} elements"
			s = s.format([words[0], words[1]])
		"@error":
			s = "Error: " + words[0]
		"@exit":
			s = "Exit Console"
			if not words.empty():
				var temp_string_array: = PoolStringArray(words)
				s += str("\n", temp_string_array.join("\n"))
				
			call_deferred("deactivate")
	
	return s

func _process_builtin_command(cmd: String, _args: Array):
	match cmd:
		"/help":
			if _args.size():
				output_text("Ignoring arguments")
			
			output_text("Commands:")
			
			for command in command_list:
				output_text(str("\t", command.command_as_string()))
			
			output_text("\t/help\n\t/types\n\t/print var")
		"/types":
			if _args.size():
				pass
			
			var lines: = [
				["bool", "values: true, false"],
				["int", "any whole number (e.g. 1)"],
				["nil", "values: null, nil"],
				["float", "any number with decimal (e.g. 1.05 or 1.0)"],
				["vector2", 'any pair of values surrounded in parenthese, like so: "(2, 5)"']
			]
			
			output_text("Parameter types:")
			
			for line in lines:
				output_text("\t%s --- %s" % [line[0], line[1]])
		"/print":
			if _args.size():
				var command: = StringCommand.new("/print", [
					{
						param = "var",
						type = -1
					}
				])
				
				var variant = command.parse_args(_args)[0]
				output_text(str(variant))
			else:
				output_text("Error: no argument provided")
		"/exit":
			deactivate()
		_:
			output_text("Error: invalid command '%s'" % cmd)
	
	return true

# Builds a command map based on the commands available in command_script.
# A properly constructed command file will have the following properties:
#   Array remote_nodes
#   Node parent_node
#   const Array valid_commands
#
# 'valid_commands' is an array where each element contains a list of components
# to a command. Each list consists of three elements:
#   [ String command, [?int param1 ... int paramN?], [?String param1 ... String paramN?]
#   
# The first element "command" is a string that specifies the name of the command.
# The name of the command must correspond to the name of a method such that
# the call() function would work.
#
# The second element is a list of integers that are used to describe the parameters
# accepted by the command. The integers specify the expected type of each parameter.
# Index 0 corresponds to the first parameter, and so on.
# Accepted values are any of the constants from Variant.Type or -1 if the parameter
# is meant to be a variant.
#
# The third element is a list of strings giving the names of each parameter. It must
# have the same number of elements as the second element.
func _init_command_map():
	command_handler.parent_node = self
	for command in command_handler.valid_commands:
		var args: = []
		for i in (command[1] as Array).size():
			args.push_back({
				param = command[2][i],
				type = command[1][i]
			})
		var _command: = StringCommand.new(command[0], args)
		command_list.push_back(_command)
	
	command_list.sort_custom(StringCommand, "_compare")

func _process(_delta):
	if (get_tree().get_frame() & 7):
		get_tree().paused = true

func _on_InputField_text_entered(new_text: String) -> void:
	input_field.clear()
	process_command(new_text)
	
	var length: int = output_box.text.length()
	if length > 999:
		output_box.text.erase(0, length - 900)
	
	output_box.cursor_set_line(1000)
	History.append_history(new_text)

func _unhandled_key_input(event: InputEventKey) -> void:
	if not visible: return
	
	if event.is_action_pressed("ui_cancel"):
		deactivate()
		get_tree().set_input_as_handled()
		return
	
	match event.scancode:
		KEY_UP:
			if event.echo: return
			goto_history_line(-1)
			get_tree().set_input_as_handled()
		KEY_DOWN:
			if event.echo: return
			goto_history_line(1)
			get_tree().set_input_as_handled()

func _on_CloseButton_pressed() -> void: deactivate()
