class_name SettingsPanel
extends CanvasLayer
## Painel de configurações (usado no menu e na pausa). Salva ao fechar.

signal closed
## O idioma mudou: telas com texto montado em código devem se redesenhar.
signal language_changed
## Apagou todo o progresso (o menu recarrega).
signal progress_reset

## Nomes dos idiomas, na ordem de Settings.LANGUAGES.
const LANGUAGE_NAMES := ["ENGLISH", "PORTUGUÊS"]

const INK := Color("2e222f")
const BORDER := Color("fbf5ef")
const ACCENT := Color("fbb954")

var _master: HSlider
var _music: HSlider
var _sfx: HSlider
var _fullscreen: CheckBox
var _shake: CheckBox
var _numbers: CheckBox
var _back: PixelButton
var _language: PixelButton
var _reset: PixelButton
## Apagar progresso só faz sentido no menu, não no meio de uma run.
var allow_reset := true


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_master.value = Settings.master_volume
	_music.value = Settings.music_volume
	_sfx.value = Settings.sfx_volume
	_fullscreen.button_pressed = Settings.fullscreen
	_shake.button_pressed = Settings.screen_shake
	_numbers.button_pressed = Settings.damage_numbers
	_update_language_button()
	_reset.visible = allow_reset
	visible = true
	_back.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	Settings.save_settings()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.07, 0.12, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	box.anti_aliasing = false
	box.set_content_margin_all(12)
	panel.add_theme_stylebox_override(&"panel", box)
	panel.custom_minimum_size = Vector2(260, 0)
	center.add_child(panel)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 4)
	panel.add_child(rows)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", ACCENT)
	title.add_theme_font_size_override(&"font_size", 14)
	rows.add_child(title)

	_master = _slider_row(rows, "VOLUME", func(v: float) -> void:
		Settings.master_volume = v
		Settings.apply())
	_music = _slider_row(rows, "MUSIC", func(v: float) -> void:
		Settings.music_volume = v
		Settings.apply())
	_sfx = _slider_row(rows, "EFFECTS", func(v: float) -> void:
		Settings.sfx_volume = v
		Settings.apply())
	_sfx.drag_ended.connect(func(_changed: bool) -> void: Sfx.play(&"ui_click"))
	_fullscreen = _check_row(rows, "FULLSCREEN", func(on: bool) -> void:
		Settings.fullscreen = on
		Settings.apply())
	_shake = _check_row(rows, "SCREEN SHAKE", func(on: bool) -> void: Settings.screen_shake = on)
	_numbers = _check_row(rows, "DAMAGE NUMBERS", func(on: bool) -> void: Settings.damage_numbers = on)

	var language_row := HBoxContainer.new()
	rows.add_child(language_row)
	language_row.add_child(_label("LANGUAGE"))
	_language = PixelButton.new()
	_language.custom_minimum_size = Vector2(120, 18)
	_language.add_theme_font_size_override(&"font_size", 8)
	# O nome de cada idioma aparece sempre na própria língua.
	_language.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_language.pressed.connect(_next_language)
	language_row.add_child(_language)

	_reset = PixelButton.new()
	_reset.text = "RESET PROGRESS"
	_reset.custom_minimum_size = Vector2(160, 18)
	_reset.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reset.add_theme_font_size_override(&"font_size", 8)
	_reset.add_theme_color_override(&"font_color", Color("e83b3b"))
	_reset.pressed.connect(_confirm_reset)
	rows.add_child(_reset)

	_back = PixelButton.new()
	_back.text = "BACK"
	_back.custom_minimum_size = Vector2(120, 24)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.add_theme_font_size_override(&"font_size", 10)
	_back.pressed.connect(close)
	rows.add_child(_back)


func _next_language() -> void:
	var index := (Settings.LANGUAGES.find(Settings.language) + 1) % Settings.LANGUAGES.size()
	Settings.language = Settings.LANGUAGES[index]
	Settings.apply()
	_update_language_button()
	language_changed.emit()


func _update_language_button() -> void:
	_language.text = LANGUAGE_NAMES[maxi(Settings.LANGUAGES.find(Settings.language), 0)]


func _confirm_reset() -> void:
	var dialog := ConfirmDialog.ask(self, tr("ERASE ALL PROGRESS?"),
		tr("SKINS, RECORDS, SOULS, UPGRADES AND THE SAVED RUN WILL BE DELETED."), "ERASE")
	dialog.confirmed.connect(func() -> void:
		GameState.reset_progress()
		close()
		progress_reset.emit())


func _slider_row(parent: Control, text: String, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	row.add_child(_label(text))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(140, 10)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Trilho e pegador no tamanho da pixel art (os do tema padrão são grandes demais aqui).
	var track := StyleBoxFlat.new()
	track.bg_color = Color("5d4a5e")
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var filled := StyleBoxFlat.new()
	filled.bg_color = ACCENT
	filled.content_margin_top = 2
	filled.content_margin_bottom = 2
	slider.add_theme_stylebox_override(&"slider", track)
	slider.add_theme_stylebox_override(&"grabber_area", filled)
	slider.add_theme_stylebox_override(&"grabber_area_highlight", filled)
	slider.add_theme_icon_override(&"grabber", _box_icon(6, 10, BORDER, true))
	slider.add_theme_icon_override(&"grabber_highlight", _box_icon(6, 10, ACCENT, true))
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return slider


func _check_row(parent: Control, text: String, on_toggle: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.add_theme_font_size_override(&"font_size", 8)
	check.add_theme_color_override(&"font_color", BORDER)
	check.add_theme_color_override(&"font_hover_color", ACCENT)
	check.add_theme_color_override(&"font_pressed_color", BORDER)
	check.add_theme_color_override(&"font_hover_pressed_color", ACCENT)
	check.add_theme_color_override(&"font_focus_color", ACCENT)
	check.add_theme_icon_override(&"unchecked", _box_icon(9, 9, BORDER, false))
	check.add_theme_icon_override(&"checked", _box_icon(9, 9, ACCENT, true))
	check.add_theme_constant_override(&"h_separation", 6)
	check.add_theme_constant_override(&"check_v_offset", 4)
	# Sem as margens do estilo padrão, que deixam cada linha alta demais nesta resolução.
	for state in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"]:
		check.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	check.toggled.connect(on_toggle)
	parent.add_child(check)
	return check


## Ícone pequeno desenhado em código: quadrado vazado ou cheio.
func _box_icon(width: int, height: int, color: Color, filled: bool) -> ImageTexture:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for x in width:
		for y in height:
			var edge := x == 0 or y == 0 or x == width - 1 or y == height - 1
			if filled or edge:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(90, 0)
	label.add_theme_font_size_override(&"font_size", 8)
	label.add_theme_color_override(&"font_color", BORDER)
	return label
