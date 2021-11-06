tool
extends LineEdit

export var default_value := ''

func _ready() -> void:
	call_deferred('reset')

func reset() -> void:
	text = default_value

func unfocus() -> void:
	if has_focus():
		release_focus()
