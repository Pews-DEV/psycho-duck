class_name ControlsPanel
extends CanvasLayer
## Como jogar: teclas desenhadas e a ação de cada uma. Aparece antes da primeira run e pela pausa.

signal closed

## [teclas, ação]. Teclas com nome ("SPACE", "MOUSE") e a ação são chaves de tradução.
const ROWS := [
	[["A", "D"], "MOVE"],
	[["W", "SPACE"], "JUMP"],
	[["S"], "DROP FROM PLATFORM"],
	[["MOUSE"], "AIM"],
	[["LEFT CLICK"], "SHOOT (HOLD)"],
	[["1", "2", "3", "4"], "PICK A CARD"],
	[["ESC", "P"], "PAUSE"],
]
const KEYS_WIDTH := 128.0

var _button: PixelButton


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


## `button_text`: "PLAY" antes da primeira run, "BACK" na pausa.
func open(button_text := "BACK") -> void:
	_button.text = button_text
	visible = true
	_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var column := UiStyle.centered_panel(self, 300, "HOW TO PLAY")
	column.add_theme_constant_override(&"separation", 4)

	for row_data in ROWS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 8)
		column.add_child(row)
		var keys := HBoxContainer.new()
		keys.alignment = BoxContainer.ALIGNMENT_END
		keys.add_theme_constant_override(&"separation", 2)
		keys.custom_minimum_size = Vector2(KEYS_WIDTH, 0)
		row.add_child(keys)
		for key in row_data[0]:
			keys.add_child(UiStyle.key_cap(tr(key)))
		var action := UiStyle.label(row_data[1], UiStyle.FONT_SMALL, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
		action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(action)

	column.add_child(UiStyle.spacer(2))
	column.add_child(UiStyle.separator())
	var goal := UiStyle.label("SURVIVE THE WAVES. PICK AN UPGRADE EACH WAVE.\nEVERY 5 WAVES THE SHOP OPENS.", UiStyle.FONT_SMALL, UiStyle.MUTED)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.custom_minimum_size = Vector2(276, 0)
	column.add_child(goal)

	_button = UiStyle.button("PLAY", UiStyle.Variant.PRIMARY)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.pressed.connect(close)
	column.add_child(_button)
