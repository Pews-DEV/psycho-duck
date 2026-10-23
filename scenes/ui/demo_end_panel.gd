class_name DemoEndPanel
extends CanvasLayer
## Fim da demo: aparece ao vencer a última onda da demo. Dá para seguir no modo infinito.

## true = seguir no modo infinito; false = voltar ao menu.
signal chosen(keep_going: bool)

var _continue: PixelButton


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var column := UiStyle.centered_panel(self, 320, UiStyle.ACCENT)
	column.add_theme_constant_override(&"separation", 10)
	column.add_child(UiStyle.label("THANKS FOR PLAYING!", 16, UiStyle.ACCENT))
	var message := UiStyle.label("YOU BEAT THE DEMO. THE FULL GAME IS ON ITS WAY.", 8, UiStyle.BORDER)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(290, 0)
	column.add_child(message)
	_continue = UiStyle.button("KEEP GOING (ENDLESS)", 10, Vector2(220, 26))
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue.pressed.connect(func() -> void:
		_close()
		chosen.emit(true))
	column.add_child(_continue)
	var menu := UiStyle.button("MENU", 10, Vector2(220, 26))
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.pressed.connect(func() -> void:
		_close()
		chosen.emit(false))
	column.add_child(menu)


func open() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play(&"skin_unlock", 0.0, 0.0)
	_continue.grab_focus()


func _close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
