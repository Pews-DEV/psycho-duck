class_name ControlsPanel
extends CanvasLayer
## Como jogar: lista de controles. Aparece antes da primeira run e pela pausa.

signal closed

## [tecla, ação]: as duas colunas são chaves de tradução.
const ROWS := [
	["A / D", "MOVE"],
	["W / SPACE", "JUMP"],
	["S", "DROP FROM PLATFORM"],
	["MOUSE", "AIM"],
	["LEFT CLICK", "SHOOT (HOLD)"],
	["1 - 4", "PICK A CARD"],
	["ESC / P", "PAUSE"],
]

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
	var column := UiStyle.centered_panel(self, 320)
	column.add_theme_constant_override(&"separation", 8)
	column.add_child(UiStyle.label("HOW TO PLAY", 14, UiStyle.ACCENT))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 16)
	grid.add_theme_constant_override(&"v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(grid)
	for row in ROWS:
		var key := UiStyle.label(row[0], 8, UiStyle.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
		key.custom_minimum_size = Vector2(110, 0)
		grid.add_child(key)
		var action := UiStyle.label(row[1], 8, UiStyle.BORDER, HORIZONTAL_ALIGNMENT_LEFT)
		action.custom_minimum_size = Vector2(150, 0)
		grid.add_child(action)

	var goal := UiStyle.label("SURVIVE THE WAVES. PICK AN UPGRADE EACH WAVE.\nEVERY 5 WAVES THE SHOP OPENS.", 7, UiStyle.MUTED)
	column.add_child(goal)

	_button = UiStyle.button("PLAY")
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.pressed.connect(close)
	column.add_child(_button)
