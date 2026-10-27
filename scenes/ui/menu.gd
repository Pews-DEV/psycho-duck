extends Control
## Menu principal. Esquerda: título e coluna de ações (a primeira é a principal).
## Direita: o pato em cima da casinha, com as setas para trocar de skin.
## Skins bloqueadas aparecem como silhueta, com a onda que as libera; JOGAR fica apagado.

const GAME_SCENE := "res://scenes/game/game.tscn"
const MENU_SCENE := "res://scenes/ui/menu.tscn"
const TITLE_TEXTURE := preload("res://assets/ui/title.png")
const ARROW_TEXTURE := preload("res://assets/ui/arrow.png")
## Título em 2× (182×26 → 364×52), centralizado no topo.
const TITLE_POS := Vector2(58, 12)
## Coluna de botões.
const BUTTONS_POS := Vector2(28, 92)
const BUTTON_SIZE := Vector2(140, 20)
## Centro do palco do pato, em pixels de tela (World está em escala 2).
const STAGE_X := 336.0
const NAME_Y := 76.0
const ARROW_Y := 112.0
const ARROW_GAP := 50.0
## Pés do pato dentro de World.
const DUCK_FEET_Y := 71.0
const DUCK_SCALE := 1.5
const LOCKED_TINT := Color(0.08, 0.06, 0.1, 0.9)

var _time := 0.0
## Skin mostrada (pode estar bloqueada); a escolhida de fato fica no GameState.
var _browse := 0
var _saved_run := {}

var _title: TextureRect
var _buttons: VBoxContainer
var _continue: PixelButton
var _play: PixelButton
var _upgrades: PixelButton
var _upgrades_badge: Control
var _options: PixelButton
var _credits: PixelButton
var _quit: PixelButton
var _name_tag: PanelContainer
var _name_label: Label
var _lock_icon: TextureRect
var _dots: Control
var _left_arrow: TextureButton
var _right_arrow: TextureButton
var _best_label: Label
var _souls_label: Label
var _skins_label: Label

@onready var duck: Sprite2D = $World/Duck
@onready var settings_panel: SettingsPanel = $SettingsPanel
@onready var meta_shop: MetaShop = $MetaShop
@onready var controls_panel: ControlsPanel = $ControlsPanel
@onready var credits_panel: CreditsPanel = $CreditsPanel


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_saved_run = GameState.load_run() if GameState.has_saved_run() else {}
	_build_title()
	_build_buttons()
	_build_skin_selector()
	_build_footer()

	settings_panel.language_changed.connect(_refresh_texts)
	settings_panel.progress_reset.connect(get_tree().change_scene_to_file.bind(MENU_SCENE))
	meta_shop.closed.connect(_refresh_texts)
	controls_panel.closed.connect(_on_controls_closed)
	for panel in [settings_panel, meta_shop, credits_panel]:
		panel.closed.connect(_focus_main)

	_browse = GameState.selected_character
	GameState.dress(duck)
	_refresh_texts()
	_focus_main()


func _process(delta: float) -> void:
	_time += delta
	_title.position.y = TITLE_POS.y + roundf(sin(_time * 2.0) * 2.0)
	var nudge := roundf(absf(sin(_time * 4.0)) * 2.0)
	_left_arrow.position.x = STAGE_X - ARROW_GAP - _left_arrow.size.x - nudge
	_right_arrow.position.x = STAGE_X + ARROW_GAP + nudge


func _unhandled_input(event: InputEvent) -> void:
	if _panel_open():
		return
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		_change_character(-1)
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		_change_character(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _panel_open() -> bool:
	return settings_panel.visible or meta_shop.visible or controls_panel.visible or credits_panel.visible


# --- Montagem ----------------------------------------------------------------

func _build_title() -> void:
	_title = TextureRect.new()
	_title.texture = TITLE_TEXTURE
	_title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title.stretch_mode = TextureRect.STRETCH_SCALE
	_title.position = TITLE_POS
	_title.size = TITLE_TEXTURE.get_size() * 2
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)


func _build_buttons() -> void:
	_buttons = VBoxContainer.new()
	_buttons.position = BUTTONS_POS
	_buttons.custom_minimum_size = Vector2(BUTTON_SIZE.x, 0)
	_buttons.add_theme_constant_override(&"separation", 5)
	add_child(_buttons)

	var has_run := not _saved_run.is_empty()
	_continue = _add_button("CONTINUE", UiStyle.Variant.PRIMARY, _continue_run)
	_continue.visible = has_run
	# Com run salva, CONTINUAR é a ação principal e JOGAR vira "nova run".
	_play = _add_button("NEW RUN" if has_run else "PLAY",
		UiStyle.Variant.SECONDARY if has_run else UiStyle.Variant.PRIMARY, _start)
	_buttons.add_child(UiStyle.spacer(2))
	_upgrades = _add_button("UPGRADES", UiStyle.Variant.SECONDARY, meta_shop.open)
	_options = _add_button("OPTIONS", UiStyle.Variant.SECONDARY, settings_panel.open)
	_credits = _add_button("CREDITS", UiStyle.Variant.SECONDARY, credits_panel.open)
	_quit = _add_button("QUIT", UiStyle.Variant.SECONDARY, get_tree().quit)
	_quit.visible = not OS.has_feature("web")

	# Selo "!" quando dá para comprar alguma melhoria permanente.
	_upgrades_badge = PanelContainer.new()
	_upgrades_badge.add_theme_stylebox_override(&"panel", UiStyle.tag_box(UiStyle.DANGER_LO, 2))
	_upgrades_badge.add_child(UiStyle.label("!", UiStyle.FONT_SMALL, UiStyle.TEXT))
	_upgrades_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upgrades.add_child(_upgrades_badge)
	_upgrades_badge.position = Vector2(BUTTON_SIZE.x - 6, -5)


func _add_button(text: String, variant: UiStyle.Variant, action: Callable) -> PixelButton:
	var node := UiStyle.button(text, variant, BUTTON_SIZE)
	node.pressed.connect(action)
	_buttons.add_child(node)
	return node


func _build_skin_selector() -> void:
	_name_tag = PanelContainer.new()
	_name_tag.add_theme_stylebox_override(&"panel", UiStyle.tag_box(UiStyle.INK, 4))
	_name_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_tag)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	_name_tag.add_child(row)
	_lock_icon = UiStyle.icon_rect("lock")
	row.add_child(_lock_icon)
	_name_label = UiStyle.label("", UiStyle.FONT_SMALL, UiStyle.ACCENT)
	row.add_child(_name_label)

	# Um quadradinho por skin: dourado = a mostrada, claro = liberada, escuro = bloqueada.
	_dots = Control.new()
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.custom_minimum_size = Vector2(GameState.SKINS.size() * 6 + 2, 11)
	_dots.draw.connect(_draw_dots)
	row.add_child(_dots)

	_left_arrow = _arrow(false)
	_left_arrow.pressed.connect(_change_character.bind(-1))
	_right_arrow = _arrow(true)
	_right_arrow.pressed.connect(_change_character.bind(1))


func _arrow(flip: bool) -> TextureButton:
	var arrow := TextureButton.new()
	arrow.texture_normal = ARROW_TEXTURE
	arrow.ignore_texture_size = true
	arrow.stretch_mode = TextureButton.STRETCH_SCALE
	arrow.flip_h = flip
	arrow.focus_mode = Control.FOCUS_NONE
	arrow.size = ARROW_TEXTURE.get_size() * 2
	arrow.position.y = ARROW_Y
	arrow.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	arrow.mouse_entered.connect(func() -> void: arrow.modulate = Color(1.2, 1.15, 0.9))
	arrow.mouse_exited.connect(func() -> void: arrow.modulate = Color.WHITE)
	add_child(arrow)
	return arrow


## Rodapé: recorde, almas e skins à esquerda; versão à direita.
func _build_footer() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	row.position = Vector2(10, 252)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.add_child(UiStyle.icon_rect("crown"))
	_best_label = _footer_label()
	row.add_child(_best_label)
	row.add_child(_footer_gap())
	row.add_child(UiStyle.soul_icon())
	_souls_label = _footer_label()
	row.add_child(_souls_label)
	row.add_child(_footer_gap())
	_skins_label = _footer_label()
	row.add_child(_skins_label)

	var version := UiStyle.label("v%s DEMO" % ProjectSettings.get_setting("application/config/version", "0.0.0"),
		UiStyle.FONT_SMALL, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_RIGHT, true)
	version.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	version.position = Vector2(330, 252)
	version.size = Vector2(140, 11)
	add_child(version)


func _footer_label() -> Label:
	var node := UiStyle.label("", UiStyle.FONT_SMALL, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	return node


func _footer_gap() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(8, 0)
	return gap


func _focus_main() -> void:
	if _continue.visible:
		_continue.grab_focus()
	elif not _play.disabled:
		_play.grab_focus()
	else:
		_upgrades.grab_focus()


# --- Estado ------------------------------------------------------------------

## Textos montados em código (mudam com o idioma e com as almas gastas na loja).
func _refresh_texts() -> void:
	_best_label.text = tr("BEST %02d") % GameState.best_wave
	_souls_label.text = str(GameState.souls)
	_skins_label.text = tr("SKINS %d/%d") % [GameState.unlocked_skin_count(), GameState.SKINS.size()]
	if not _saved_run.is_empty():
		_continue.text = tr("CONTINUE - WAVE %02d") % int(_saved_run.get("wave", 1))
	_upgrades_badge.visible = _can_buy_meta()
	_refresh(false)


func _can_buy_meta() -> bool:
	for upgrade in GameState.META_UPGRADES:
		var level := GameState.meta_level(upgrade)
		if level < upgrade.max_level and GameState.souls >= upgrade.cost_for(level):
			return true
	return false


func _change_character(step: int) -> void:
	_browse = wrapi(_browse + step, 0, GameState.SKINS.size())
	Sfx.play(&"ui_click", -4.0, 0.0, 1.0 if GameState.is_skin_unlocked(_browse) else 0.7)
	GameState.select_skin(_browse)
	_refresh(true)


func _refresh(animate: bool) -> void:
	var skin: SkinData = GameState.SKINS[_browse]
	var unlocked := GameState.is_skin_unlocked(_browse)
	duck.texture = skin.texture
	duck.modulate = Color.WHITE if unlocked else LOCKED_TINT
	_lock_icon.visible = not unlocked
	_name_label.text = tr(skin.display_name).to_upper() if unlocked else tr("CLEAR WAVE %d") % skin.unlock_wave
	_name_label.add_theme_color_override(&"font_color", UiStyle.ACCENT if unlocked else UiStyle.MUTED)
	_play.disabled = not unlocked
	_continue.disabled = false
	# Centraliza a etiqueta do nome em cima do pato depois que o texto muda de tamanho.
	_name_tag.reset_size()
	_name_tag.position = Vector2(roundf(STAGE_X - _name_tag.size.x / 2.0), NAME_Y)
	_dots.queue_redraw()
	if not animate:
		return
	var tween := create_tween()
	duck.scale = Vector2(DUCK_SCALE * 1.3, DUCK_SCALE * 0.7)
	tween.tween_property(duck, "scale", Vector2(DUCK_SCALE, DUCK_SCALE), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var hop := create_tween()
	hop.tween_property(duck, "position:y", DUCK_FEET_Y - 8.0, 0.1).set_ease(Tween.EASE_OUT)
	hop.tween_property(duck, "position:y", DUCK_FEET_Y, 0.15).set_ease(Tween.EASE_IN)


func _draw_dots() -> void:
	for i in GameState.SKINS.size():
		var color := UiStyle.SURFACE_HI
		if i == _browse:
			color = UiStyle.ACCENT
		elif GameState.is_skin_unlocked(i):
			color = UiStyle.MUTED
		var at := Vector2(4 + i * 6, 4)
		_dots.draw_rect(Rect2(at - Vector2.ONE, Vector2(6, 6)), UiStyle.INK)
		_dots.draw_rect(Rect2(at, Vector2(4, 4)), color)


# --- Ações -------------------------------------------------------------------

## Nova run. Se houver run salva, pede confirmação antes de descartá-la.
func _start() -> void:
	if not GameState.is_skin_unlocked(_browse):
		Sfx.play(&"deny", -4.0, 0.0)
		return
	if _saved_run.is_empty():
		_begin_new_run()
		return
	var dialog := ConfirmDialog.ask(self, tr("START A NEW RUN?"),
		tr("YOUR SAVED RUN (WAVE %02d) WILL BE LOST.") % int(_saved_run.get("wave", 1)), "NEW RUN", true)
	dialog.confirmed.connect(_begin_new_run)
	dialog.cancelled.connect(_play.grab_focus)


func _begin_new_run() -> void:
	GameState.resume_requested = false
	# Primeira run: mostra os controles antes de jogar.
	if not GameState.seen_controls:
		controls_panel.open("PLAY")
		return
	_go_to_game()


func _on_controls_closed() -> void:
	if not GameState.seen_controls:
		GameState.mark_controls_seen()
		_go_to_game()


func _continue_run() -> void:
	GameState.selected_character = int(_saved_run.get("skin", 0))
	GameState.resume_requested = true
	_go_to_game()


func _go_to_game() -> void:
	Sfx.play(&"card_pick", -2.0, 0.0)
	for node in _buttons.get_children():
		if node is Button:
			node.disabled = true
	var fade := ColorRect.new()
	fade.color = Color(UiStyle.INK, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.25)
	tween.tween_callback(get_tree().change_scene_to_file.bind(GAME_SCENE))
