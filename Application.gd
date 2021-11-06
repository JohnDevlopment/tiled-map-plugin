tool
extends Node

static func print_fields(fields: Array):
	for field in fields:
		print("%s: %s" % [field.name, field.value])

static func print_to_file(path: String, data):
	var file := File.new()
	var err := file.open(path, File.WRITE)
	if err:
		return err
	
	if data is Dictionary or data is Array:
		var out := JSON.print(data, "\t")
		file.store_string(out)
	else:
		file.store_var(data)
	
	file.close()
	
	return OK

func exit(exit_code: int = -1) -> void:
	get_tree().quit(exit_code)
