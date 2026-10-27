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
	var column := UiStyle.centered_panel(self, 300, "THANKS FOR PLAYING!", UiStyle.ACCENT)
	column.add_theme_constant_override(&"separation", 8)
	var crown := UiStyle.icon_rect("crown")
	crown.custom_minimum_size = Vector2(7, 9)
	column.add_child(crown)
	var message := UiStyle.label("YOU BEAT THE DEMO. THE FULL GAME IS ON ITS WAY.", UiStyle.FONT_SMALL, UiStyle.TEXT)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size = Vector2(276, 0)
	column.add_child(message)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 8)
	column.add_child(buttons)
	var menu := UiStyle.button("MENU", UiStyle.Variant.SECONDARY, Vector2(100, 20))
	menu.pressed.connect(func() -> void:
		_close()
		chosen.emit(false))
	buttons.add_child(menu)
	_continue = UiStyle.button("KEEP GOING (ENDLESS)", UiStyle.Variant.PRIMARY, Vector2(160, 20))
	_continue.pressed.connect(func() -> void:
		_close()
		chosen.emit(true))
	buttons.add_child(_continue)


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
