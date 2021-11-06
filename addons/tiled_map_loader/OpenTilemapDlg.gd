tool
extends WindowDialog

export var popup_size := Vector2() setget set_popup_size
export var debug_visible := false

var editor_interface: EditorInterface

var _update_timer: Timer
var _line_edit: LineEdit

func _enter_tree() -> void:
	visible = debug_visible
	
	if not Engine.editor_hint:
		_update_timer = Timer.new()
		_update_timer.autostart = false
		_update_timer.one_shot = true
		_update_timer.connect('timeout', self, '_update_popup', [], CONNECT_DEFERRED)
		add_child(_update_timer)

func _ready() -> void:
	if not Engine.editor_hint and debug_visible:
		call_deferred('popup_centered', popup_size)

func set_popup_size(v) -> void:
	popup_size = v
	
	if not Engine.editor_hint:
		if is_instance_valid(_update_timer):
			_update_timer.start(1)

func show_dialog() -> void: popup_centered(popup_size)

# Called when the timer is finished
func _update_popup():
	hide()
	popup_centered(popup_size)

func _on_FileDialog_about_to_show() -> void:
	var initial_dir = ProjectSettings.get_setting('tiled_map_loader/initial_dir')
	if initial_dir is String:
		$FileDialog.current_dir = initial_dir

func _on_FileDialog_file_selected(path: String) -> void:
	_line_edit.text = path

func _browse_log_file() -> void:
	_line_edit = $MarginContainer/VBoxContainer/LogLine/LogFile
	
	var file_dlg: FileDialog = $FileDialog
	file_dlg.mode = FileDialog.MODE_SAVE_FILE
	file_dlg.current_dir = 'res://'
	file_dlg.popup_centered()

func _browse_open_file() -> void:
	_line_edit = $MarginContainer/VBoxContainer/FileLine/InputFile
	
	var file_dlg: FileDialog = $FileDialog
	file_dlg.mode = FileDialog.MODE_OPEN_FILE
	file_dlg.popup_centered()

func _load_tilemap() -> void:
	var dir := Directory.new()
	var log_file: String = $MarginContainer/VBoxContainer/LogLine/LogFile.text
	var input_file: String = $MarginContainer/VBoxContainer/FileLine/InputFile.text
	
	if log_file.empty() or not dir.dir_exists(log_file.get_base_dir()):
		printerr("Directory '%s' does not exist or is undefined." % log_file.get_base_dir())
		return
	
	if input_file.empty() or not dir.file_exists(input_file):
		printerr("Input file '%s' does not exist or is undefined." % input_file)
		return
	
	# Write dictionary to file in JSON format
	var tmx_to_dict := preload('res://addons/tiled_map_loader/tiled_xml_to_dict.gd').new()
	
	var tmx_data = tmx_to_dict.read_tmx(input_file)
	if not tmx_data is Dictionary: return
	
	var file := File.new()
	if file.open(log_file, File.WRITE): return
	file.store_string(JSON.print(tmx_data, "\t"))
	file.close()
	
	hide()

func _reset_members():
	$MarginContainer/VBoxContainer/FileLine/InputFile.text = ''
	$MarginContainer/VBoxContainer/LogLine/LogFile.text = ''
	
	for node in [$MarginContainer/VBoxContainer/Options/Margin, $MarginContainer/VBoxContainer/Options/Spacing]:
		node.reset()
		node.enabled = false

func _close_dialog() -> void:
	_reset_members()
