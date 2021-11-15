tool
extends WindowDialog

var file_dialog: Popup
var input_file: LineEdit
var user_notification: AcceptDialog
var editor_interface: EditorInterface

func _ready() -> void:
	file_dialog = $FileDialog
	input_file = $MarginContainer/VBoxContainer/FileLine/InputFile
	user_notification = $UserNotification

func open_file_dialog() -> void:
	(file_dialog as Popup).popup_centered_clamped(Vector2(700, 400))

func show_dialog() -> void:
	popup_centered(Vector2(430, 400))

func _create_tileset() -> void:
	var tsx_loader = preload('res://addons/tiled_map_loader/tiled_map_loader.gd').new()
	var source_path: String = input_file.text
	if not source_path.empty():
		var tileset = tsx_loader.build_tileset(source_path)
		if not tileset is TileSet:
			user_notification.dialog_text = "There was an error while processing '%s'. Please refer to the console to see what the problem is." % source_path
			user_notification.popup_centered()
			user_notification.grab_focus()
		else:
			hide()
			if Engine.editor_hint:
				editor_interface.edit_resource(tileset)

func _on_FileDialog_file_selected(path: String) -> void:
	(input_file as LineEdit).text = path

func _on_hiding_dialog() -> void:
	input_file.text = ''

func _on_UserNotification_confirmed() -> void:
	hide()

func _on_FileDialog_about_to_show() -> void:
	(file_dialog as FileDialog).current_dir = ProjectSettings.get_setting('tiled_map_loader/initial_dir')
