tool
extends "res://addons/tiled_map_loader/ConditionalOption.gd"

func get_data() -> int: return int($Input.text)

func _accept_int(v: String) -> void:
	var input = $Input
	var temp = int(input.text)
	input.text = str(temp)
