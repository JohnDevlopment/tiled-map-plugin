tool
extends VBoxContainer

export var option_name := '' setget set_option_name
export var enabled := true setget enable
export var type := ''

func enable(param) -> void:
	enabled = param
	$Input.visible = enabled
	$CheckButton.pressed = param
	if not enabled:
		$Input.reset()

func get_data(): return ''

func reset() -> void:
	enable(false)

func set_option_name(param) -> void:
	option_name = param
	var temp := option_name
	if temp == '': temp = '[Option Name]'
	$CheckButton.text = temp
	$Input.placeholder_text = temp

func _accept_input(new_text: String) -> void:
	var funcname := '_accept_' + type
	
	if has_method(funcname):
		call(funcname, new_text)

func _enable_input(button_pressed: bool) -> void:
	enable(button_pressed)

func _on_Input_focus_exited() -> void:
	var input = $Input
	if input.text.empty():
		input.reset()
	
	_accept_input(input.text)
