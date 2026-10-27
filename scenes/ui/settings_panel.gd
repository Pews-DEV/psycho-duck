class_name SettingsPanel
extends CanvasLayer
## Painel de configurações (usado no menu e na pausa). Salva ao fechar.
## Seções: som (sliders com %) e jogo (chaves liga/desliga e idioma).

signal closed
## O idioma mudou: telas com texto montado em código devem se redesenhar.
signal language_changed
## Apagou todo o progresso (o menu recarrega).
signal progress_reset

## Nomes dos idiomas, na ordem de Settings.LANGUAGES.
const LANGUAGE_NAMES := ["ENGLISH", "PORTUGUÊS"]
const LABEL_WIDTH := 112.0
const CONTROL_WIDTH := 132.0

var _master: HSlider
var _music: HSlider
var _sfx: HSlider
var _fullscreen: PixelButton
var _shake: PixelButton
var _numbers: PixelButton
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
	_set_toggle(_fullscreen, Settings.fullscreen)
	_set_toggle(_shake, Settings.screen_shake)
	_set_toggle(_numbers, Settings.damage_numbers)
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
	var column := UiStyle.centered_panel(self, 280, "SETTINGS")
	column.add_theme_constant_override(&"separation", 4)

	_master = _slider_row(column, "VOLUME", func(v: float) -> void:
		Settings.master_volume = v
		Settings.apply())
	_music = _slider_row(column, "MUSIC", func(v: float) -> void:
		Settings.music_volume = v
		Settings.apply())
	_sfx = _slider_row(column, "EFFECTS", func(v: float) -> void:
		Settings.sfx_volume = v
		Settings.apply())
	_sfx.drag_ended.connect(func(_changed: bool) -> void: Sfx.play(&"ui_click"))

	column.add_child(UiStyle.separator())
	_fullscreen = _toggle_row(column, "FULLSCREEN", func(on: bool) -> void:
		Settings.fullscreen = on
		Settings.apply())
	_shake = _toggle_row(column, "SCREEN SHAKE", func(on: bool) -> void: Settings.screen_shake = on)
	_numbers = _toggle_row(column, "DAMAGE NUMBERS", func(on: bool) -> void: Settings.damage_numbers = on)

	var language_row := _row(column, "LANGUAGE")
	_language = UiStyle.button("", UiStyle.Variant.SECONDARY, Vector2(CONTROL_WIDTH, 18))
	# O nome de cada idioma aparece sempre na própria língua.
	_language.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_language.pressed.connect(_next_language)
	language_row.add_child(_language)

	column.add_child(UiStyle.separator())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override(&"separation", 8)
	column.add_child(footer)
	_reset = UiStyle.button("RESET PROGRESS", UiStyle.Variant.DANGER, Vector2(130, 20))
	_reset.pressed.connect(_confirm_reset)
	footer.add_child(_reset)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(fill)
	_back = UiStyle.button("BACK", UiStyle.Variant.PRIMARY, Vector2(110, 20))
	_back.pressed.connect(close)
	footer.add_child(_back)


func _row(parent: Control, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	parent.add_child(row)
	var name_label := UiStyle.label(text, UiStyle.FONT_SMALL, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	return row


func _next_language() -> void:
	var index := (Settings.LANGUAGES.find(Settings.language) + 1) % Settings.LANGUAGES.size()
	Settings.language = Settings.LANGUAGES[index]
	Settings.apply()
	_update_language_button()
	language_changed.emit()


func _update_language_button() -> void:
	_language.text = "< %s >" % LANGUAGE_NAMES[maxi(Settings.LANGUAGES.find(Settings.language), 0)]


func _confirm_reset() -> void:
	var dialog := ConfirmDialog.ask(self, tr("ERASE ALL PROGRESS?"),
		tr("SKINS, RECORDS, SOULS, UPGRADES AND THE SAVED RUN WILL BE DELETED."), "ERASE", true)
	dialog.confirmed.connect(func() -> void:
		GameState.reset_progress()
		close()
		progress_reset.emit())
	dialog.cancelled.connect(_reset.grab_focus)


## Slider em pixel art com a porcentagem à direita.
func _slider_row(parent: Control, text: String, on_change: Callable) -> HSlider:
	var row := _row(parent, text)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(CONTROL_WIDTH - 30, 11)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var track := StyleBoxFlat.new()
	track.bg_color = UiStyle.PLUM
	track.border_color = UiStyle.INK
	track.set_border_width_all(1)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var filled := StyleBoxFlat.new()
	filled.bg_color = UiStyle.ACCENT
	filled.border_color = UiStyle.INK
	filled.set_border_width_all(1)
	filled.content_margin_top = 2
	filled.content_margin_bottom = 2
	slider.add_theme_stylebox_override(&"slider", track)
	slider.add_theme_stylebox_override(&"grabber_area", filled)
	slider.add_theme_stylebox_override(&"grabber_area_highlight", filled)
	slider.add_theme_icon_override(&"grabber", _grabber(UiStyle.TEXT))
	slider.add_theme_icon_override(&"grabber_highlight", _grabber(UiStyle.GOLD_HI))
	slider.add_theme_icon_override(&"grabber_disabled", _grabber(UiStyle.LINE))
	# Foco por teclado: o pegador fica dourado (sem o retângulo padrão do tema).
	slider.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	row.add_child(slider)
	var value := UiStyle.label("0%", UiStyle.FONT_SMALL, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	value.custom_minimum_size = Vector2(26, 0)
	value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(value)
	slider.value_changed.connect(func(v: float) -> void:
		value.text = "%d%%" % roundi(v * 100.0)
		on_change.call(v))
	slider.focus_entered.connect(func() -> void: slider.add_theme_icon_override(&"grabber", _grabber(UiStyle.GOLD_HI)))
	slider.focus_exited.connect(func() -> void: slider.add_theme_icon_override(&"grabber", _grabber(UiStyle.TEXT)))
	return slider


## Chave liga/desliga: botão comum que alterna entre ON (dourado) e OFF.
## (Sem toggle_mode: ligado, o botão ficaria com o visual de "apertado".)
func _toggle_row(parent: Control, text: String, on_toggle: Callable) -> PixelButton:
	var row := _row(parent, text)
	var toggle := UiStyle.button("OFF", UiStyle.Variant.SECONDARY, Vector2(CONTROL_WIDTH, 18))
	row.add_child(toggle)
	toggle.pressed.connect(func() -> void:
		var on := not bool(toggle.get_meta(&"on", false))
		_set_toggle(toggle, on)
		on_toggle.call(on))
	return toggle


func _set_toggle(toggle: PixelButton, on: bool) -> void:
	toggle.set_meta(&"on", on)
	toggle.text = "ON" if on else "OFF"
	toggle.variant = UiStyle.Variant.PRIMARY if on else UiStyle.Variant.SECONDARY


## Pegador 5×9 com contorno escuro.
func _grabber(color: Color) -> ImageTexture:
	var image := Image.create(5, 9, false, Image.FORMAT_RGBA8)
	for x in 5:
		for y in 9:
			var edge := x == 0 or y == 0 or x == 4 or y == 8
			image.set_pixel(x, y, UiStyle.INK if edge else color)
	return ImageTexture.create_from_image(image)
