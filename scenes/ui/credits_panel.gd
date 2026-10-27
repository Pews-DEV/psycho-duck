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
	var column := UiStyle.centered_panel(self, 340, "CREDITS")
	column.add_theme_constant_override(&"separation", 4)

	var logo_row := HBoxContainer.new()
	logo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_row.add_theme_constant_override(&"separation", 10)
	column.add_child(logo_row)
	var logo := TextureRect.new()
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(48, 48)
	# O logo não é pixel art: filtro suave para reduzir sem serrilhar.
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	logo_row.add_child(logo)
	var by := VBoxContainer.new()
	by.alignment = BoxContainer.ALIGNMENT_CENTER
	by.add_theme_constant_override(&"separation", 0)
	logo_row.add_child(by)
	by.add_child(UiStyle.label("A GAME BY", UiStyle.FONT_SMALL, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	var studio := UiStyle.label("BRIBA STUDIO", UiStyle.FONT_LARGE, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	studio.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	by.add_child(studio)

	column.add_child(UiStyle.separator())
	for section in SECTIONS:
		var block := VBoxContainer.new()
		block.add_theme_constant_override(&"separation", -1)
		column.add_child(block)
		block.add_child(UiStyle.label(section[0], UiStyle.FONT_SMALL, UiStyle.ACCENT))
		var value := UiStyle.label(section[1], UiStyle.FONT_SMALL, UiStyle.TEXT)
		value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value.custom_minimum_size = Vector2(316, 0)
		block.add_child(value)

	column.add_child(UiStyle.spacer(2))
	_back = UiStyle.button("BACK", UiStyle.Variant.PRIMARY)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	column.add_child(_back)
