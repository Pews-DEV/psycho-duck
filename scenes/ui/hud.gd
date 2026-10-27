extends CanvasLayer
## HUD da partida, montada em código sobre a grade de 480×270.
##   Esquerda-topo  - o pato: vida (barra com rastro do dano) e almas da run.
##   Direita-topo   - a onda: número, progresso (inimigos restantes) e o próximo evento.
##   Centro-topo    - o chefe: nome e vida, só enquanto ele está vivo.
##   Centro         - faixa de aviso (ONDA 05, ONDA VENCIDA...).
##   Esquerda-baixo - carga do poste de luz, depois de construído.
##   Bordas         - setas de inimigos fora da tela e brilho vermelho com pouca vida.

const MARGIN := 8.0
const HP_BAR := Rect2(19, 10, 92, 6)
const WAVE_BAR_WIDTH := 70.0
const BOSS_BAR := Rect2(150, 19, 180, 5)
const BANNER_Y := 70.0
## Abaixo desta fração de vida, as bordas da tela pulsam em vermelho.
const LOW_HP := 0.3
## O rastro branco da barra de vida desce a esta velocidade (fração por segundo).
const GHOST_SPEED := 0.6

## Setas na borda da tela para inimigos fora da visão (a arena pode ser mais larga).
const VIEW_SIZE := View.SIZE
const INDICATOR_COLOR := UiStyle.TEXT
const INDICATOR_DANGER := UiStyle.DANGER

var _hp := 25.0
var _max_hp := 25.0
var _ghost := 1.0
var _hp_flash := 0.0
var _boss_ratio := 1.0
var _boss_ghost := 1.0
var _pole: LightPole
var _spawner: WaveSpawner
var _time := 0.0

var _hp_label: Label
var _souls_label: Label
var _wave_number: Label
var _wave_caption: Label
var _remaining_label: Label
var _next_icon: TextureRect
var _next_label: Label
var _bars: Control
var _boss_box: Control
var _boss_name: Label
var _banner: Control
var _banner_label: Label
var _pole_box: Control
var _vignette: Control
var _indicators: Control


func _ready() -> void:
	_build()


func _process(delta: float) -> void:
	_time += delta
	_ghost = move_toward(_ghost, _ratio(), GHOST_SPEED * delta) if _ghost > _ratio() else _ratio()
	_boss_ghost = move_toward(_boss_ghost, _boss_ratio, GHOST_SPEED * delta) if _boss_ghost > _boss_ratio else _boss_ratio
	_hp_flash = maxf(_hp_flash - delta * 6.0, 0.0)
	if _spawner == null:
		_spawner = get_tree().get_first_node_in_group(&"wave_spawner") as WaveSpawner
	if _spawner:
		_remaining_label.text = str(maxi(_spawner.wave_total - _spawner.wave_killed, 0))
	_pole_box.visible = _pole != null and is_instance_valid(_pole)
	var low := _hp > 0.0 and _ratio() <= LOW_HP
	_vignette.visible = low
	if low:
		_vignette.modulate.a = 0.75 + 0.25 * sin(_time * 6.0)
	_bars.queue_redraw()
	_indicators.queue_redraw()


func _ratio() -> float:
	return clampf(_hp / _max_hp, 0.0, 1.0) if _max_hp > 0.0 else 0.0


# --- API usada pelo jogo ------------------------------------------------------------

func set_health(hp: float, max_hp: float) -> void:
	if hp < _hp:
		_hp_flash = 1.0
	_hp = hp
	_max_hp = max_hp
	_hp_label.text = "%d/%d" % [ceili(hp), roundi(max_hp)]


## `boss`: esta onda tem chefe. `shop_wave`: a loja abre ao vencer esta onda (0 = não mostrar).
func set_wave(wave: int, boss := false, shop_wave := 0) -> void:
	_wave_number.text = "%02d" % wave
	_pop(_wave_number)
	if boss:
		_next_icon.texture = UiStyle.icon("crown")
		_next_label.text = tr("BOSS WAVE")
		_next_label.add_theme_color_override(&"font_color", UiStyle.DANGER)
	elif shop_wave > 0:
		_next_icon.texture = UiStyle.icon("shop")
		_next_label.text = tr("SHOP AFTER THIS WAVE") if shop_wave == wave else tr("SHOP AFTER WAVE %02d") % shop_wave
		_next_label.add_theme_color_override(&"font_color", UiStyle.ACCENT if shop_wave == wave else UiStyle.MUTED)
	_next_icon.visible = boss or shop_wave > 0
	_next_label.visible = _next_icon.visible


func set_souls(souls: int) -> void:
	_souls_label.text = str(souls)
	_pop(_souls_label)


func show_banner(text: String, color := UiStyle.ACCENT) -> void:
	_banner_label.text = text
	_banner_label.add_theme_color_override(&"font_color", color)
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.4)


func show_boss(boss: Enemy) -> void:
	_boss_name.text = tr(boss.data.display_name).to_upper()
	_boss_ratio = 1.0
	_boss_ghost = 1.0
	_boss_box.visible = true
	boss.health_changed.connect(func(hp: float, max_hp: float) -> void: _boss_ratio = hp / max_hp)
	boss.died.connect(func(_dead: Enemy) -> void: _boss_box.visible = false)


## O poste foi construído: mostra a carga da rajada no canto.
func set_pole(pole: LightPole) -> void:
	_pole = pole


# --- Montagem ----------------------------------------------------------------------

func _build() -> void:
	# Bordas vermelhas de pouca vida (embaixo de tudo).
	_vignette = Control.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.draw.connect(_draw_vignette)
	_vignette.visible = false
	add_child(_vignette)

	# Todas as barras são desenhadas num só Control.
	_bars = Control.new()
	_bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.draw.connect(_draw_bars)
	add_child(_bars)

	# --- Pato: vida e almas ---
	_place(UiStyle.icon_rect("heart"), Vector2(MARGIN, 8))
	_hp_label = _outlined("", HORIZONTAL_ALIGNMENT_LEFT)
	_place(_hp_label, Vector2(HP_BAR.end.x + 5, 7))
	_place(UiStyle.soul_icon(), Vector2(MARGIN - 1, 19))
	_souls_label = _outlined("0", HORIZONTAL_ALIGNMENT_LEFT)
	_place(_souls_label, Vector2(HP_BAR.position.x, 19))

	# --- Onda: número, restantes e próximo evento (alinhados à direita) ---
	var right := VIEW_SIZE.x - MARGIN
	var wave_row := HBoxContainer.new()
	wave_row.alignment = BoxContainer.ALIGNMENT_END
	wave_row.add_theme_constant_override(&"separation", 3)
	wave_row.position = Vector2(right - 120, 2)
	wave_row.size = Vector2(120, 21)
	wave_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wave_row)
	_wave_caption = _outlined("WAVE", HORIZONTAL_ALIGNMENT_RIGHT, UiStyle.MUTED)
	_wave_caption.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_INHERIT
	_wave_caption.size_flags_vertical = Control.SIZE_SHRINK_END
	wave_row.add_child(_wave_caption)
	_wave_number = UiStyle.label("01", UiStyle.FONT_LARGE, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_RIGHT, true)
	_wave_number.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	wave_row.add_child(_wave_number)

	var remaining_row := HBoxContainer.new()
	remaining_row.alignment = BoxContainer.ALIGNMENT_END
	remaining_row.add_theme_constant_override(&"separation", 3)
	remaining_row.position = Vector2(right - WAVE_BAR_WIDTH - 40, 22)
	remaining_row.size = Vector2(34, 11)
	remaining_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(remaining_row)
	remaining_row.add_child(UiStyle.icon_rect("skull"))
	_remaining_label = _outlined("0", HORIZONTAL_ALIGNMENT_RIGHT)
	remaining_row.add_child(_remaining_label)

	var next_row := HBoxContainer.new()
	next_row.alignment = BoxContainer.ALIGNMENT_END
	next_row.add_theme_constant_override(&"separation", 3)
	next_row.position = Vector2(right - 200, 33)
	next_row.size = Vector2(200, 11)
	next_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(next_row)
	_next_icon = UiStyle.icon_rect("shop")
	next_row.add_child(_next_icon)
	_next_label = _outlined("", HORIZONTAL_ALIGNMENT_RIGHT, UiStyle.MUTED)
	next_row.add_child(_next_label)

	# --- Chefe ---
	_boss_box = Control.new()
	_boss_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	add_child(_boss_box)
	var boss_row := HBoxContainer.new()
	boss_row.alignment = BoxContainer.ALIGNMENT_CENTER
	boss_row.add_theme_constant_override(&"separation", 4)
	boss_row.position = Vector2(BOSS_BAR.position.x, 5)
	boss_row.size = Vector2(BOSS_BAR.size.x, 11)
	boss_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.add_child(boss_row)
	boss_row.add_child(UiStyle.icon_rect("crown"))
	_boss_name = _outlined("", HORIZONTAL_ALIGNMENT_CENTER, UiStyle.ACCENT)
	boss_row.add_child(_boss_name)

	# --- Poste ---
	_pole_box = Control.new()
	_pole_box.position = Vector2(MARGIN, VIEW_SIZE.y - 18)
	_pole_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pole_box.visible = false
	add_child(_pole_box)
	_pole_box.add_child(UiStyle.icon_rect("lamp"))

	# --- Faixa de aviso ---
	_banner = Control.new()
	_banner.position = Vector2(0, BANNER_Y)
	_banner.size = Vector2(VIEW_SIZE.x, 26)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	_banner.draw.connect(func() -> void:
		_banner.draw_rect(Rect2(0, 0, _banner.size.x, _banner.size.y), Color(UiStyle.INK, 0.75))
		_banner.draw_rect(Rect2(0, 0, _banner.size.x, 1), UiStyle.SURFACE_HI)
		_banner.draw_rect(Rect2(0, _banner.size.y - 1, _banner.size.x, 1), UiStyle.SURFACE_HI))
	add_child(_banner)
	_banner_label = UiStyle.label("", UiStyle.FONT_LARGE, UiStyle.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, true)
	_banner_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.position = Vector2(0, 2)
	_banner_label.size = Vector2(VIEW_SIZE.x, 22)
	_banner.add_child(_banner_label)

	_indicators = Control.new()
	_indicators.set_anchors_preset(Control.PRESET_FULL_RECT)
	_indicators.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicators.draw.connect(_draw_indicators)
	add_child(_indicators)


func _outlined(text: String, align: HorizontalAlignment, color := UiStyle.TEXT) -> Label:
	var node := UiStyle.label(text, UiStyle.FONT_SMALL, color, align, true)
	node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	return node


func _place(node: Control, at: Vector2) -> void:
	node.position = at
	add_child(node)


func _pop(label: Label) -> void:
	label.pivot_offset = (label.size / 2.0).round()
	label.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.15)


# --- Desenho -------------------------------------------------------------------------

func _draw_bars() -> void:
	# Vida: pisca branca ao tomar dano; o rastro branco mostra o quanto se perdeu.
	var hp_color := UiStyle.DANGER.lerp(UiStyle.TEXT, _hp_flash * 0.7)
	UiStyle.draw_bar(_bars, HP_BAR, _ratio(), hp_color, _ghost, UiStyle.DANGER_HI)

	# Progresso da onda: quanto já foi derrotado.
	var right := VIEW_SIZE.x - MARGIN
	var wave_rect := Rect2(right - WAVE_BAR_WIDTH, 25, WAVE_BAR_WIDTH, 4)
	var progress := 0.0
	if _spawner and _spawner.wave_total > 0:
		progress = float(_spawner.wave_killed) / _spawner.wave_total
	UiStyle.draw_bar(_bars, wave_rect, progress, UiStyle.ACCENT)

	if _boss_box.visible:
		UiStyle.draw_bar(_bars, BOSS_BAR, _boss_ratio, UiStyle.GOLD, _boss_ghost, UiStyle.TEXT)

	if _pole_box.visible:
		var pole_rect := Rect2(_pole_box.position + Vector2(11, 4), Vector2(40, 3))
		var charge := _pole.charge()
		UiStyle.draw_bar(_bars, pole_rect, charge, UiStyle.GOLD_HI if charge >= 1.0 else UiStyle.STEEL)


## Bordas vermelhas em faixas de pixel (sem degradê suave), mais fortes no canto.
func _draw_vignette() -> void:
	var size := VIEW_SIZE
	var bands := [[0, 0.5], [3, 0.32], [6, 0.18], [10, 0.08]]
	for band in bands:
		var inset: float = band[0]
		var color := Color(UiStyle.DANGER, band[1])
		var thickness := 3.0 if inset < 10 else 4.0
		_vignette.draw_rect(Rect2(inset, inset, size.x - inset * 2, thickness), color)
		_vignette.draw_rect(Rect2(inset, size.y - inset - thickness, size.x - inset * 2, thickness), color)
		_vignette.draw_rect(Rect2(inset, inset + thickness, thickness, size.y - (inset + thickness) * 2), color)
		_vignette.draw_rect(Rect2(size.x - inset - thickness, inset + thickness, thickness, size.y - (inset + thickness) * 2), color)


func _draw_indicators() -> void:
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.is_dying:
			continue
		var at: Vector2 = enemy.get_global_transform_with_canvas().origin
		if at.x >= 0.0 and at.x <= VIEW_SIZE.x:
			continue
		var y := roundf(clampf(at.y, 50.0, 220.0))
		var color := INDICATOR_DANGER if enemy.elite or enemy.data.max_hp >= 500.0 else INDICATOR_COLOR
		var blink := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 120.0)
		var points: PackedVector2Array
		var outline: PackedVector2Array
		if at.x < 0.0:
			points = [Vector2(4, y), Vector2(10, y - 5), Vector2(10, y + 5)]
			outline = [Vector2(2, y), Vector2(11, y - 7), Vector2(11, y + 7)]
		else:
			points = [Vector2(VIEW_SIZE.x - 4, y), Vector2(VIEW_SIZE.x - 10, y - 5), Vector2(VIEW_SIZE.x - 10, y + 5)]
			outline = [Vector2(VIEW_SIZE.x - 2, y), Vector2(VIEW_SIZE.x - 11, y - 7), Vector2(VIEW_SIZE.x - 11, y + 7)]
		_indicators.draw_colored_polygon(outline, Color(UiStyle.INK, blink))
		_indicators.draw_colored_polygon(points, Color(color, blink))
