class_name CreditsPanel
extends CanvasLayer
## Créditos: estúdio, funções e licenças (a fonte Silkscreen pede atribuição pela OFL).

signal closed

const LOGO := preload("res://assets/branding/briba_logo.png")
const SECTIONS := [
	["DESIGN, ART AND CODE", "BRIBA STUDIO"],
	["MUSIC AND SOUND", "BRIBA STUDIO"],
	["FONT", "SILKSCREEN BY JASON KOTTKE - SIL OPEN FONT LICENSE 1.1"],
	["MADE WITH", "GODOT ENGINE - MIT LICENSE"],
]

var _back: PixelButton


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	visible = true
	_back.grab_focus()


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
	var column := UiStyle.centered_panel(self, 360)
	column.add_theme_constant_override(&"separation", 4)
	column.add_child(UiStyle.label("CREDITS", 14, UiStyle.ACCENT))

	var logo_row := HBoxContainer.new()
	logo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_row.add_theme_constant_override(&"separation", 10)
	column.add_child(logo_row)
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(72, 72)
	# O logo não é pixel art: filtro suave para reduzir sem serrilhar.
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo_row.add_child(logo)
	var by := VBoxContainer.new()
	by.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_row.add_child(by)
	by.add_child(UiStyle.label("A GAME BY", 7, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	by.add_child(UiStyle.label("BRIBA STUDIO", 12, UiStyle.BORDER, HORIZONTAL_ALIGNMENT_LEFT))

	for section in SECTIONS:
		column.add_child(UiStyle.label(section[0], 7, UiStyle.ACCENT))
		var value := UiStyle.label(section[1], 7, UiStyle.BORDER)
		value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		column.add_child(value)

	column.add_child(UiStyle.label("THANK YOU FOR PLAYING", 8, UiStyle.MUTED))
	_back = UiStyle.button("BACK")
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	column.add_child(_back)
