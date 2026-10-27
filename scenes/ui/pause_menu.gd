extends CanvasLayer
## Esc pausa. Esquerda: continuar, configurações, controles, salvar e sair, desistir.
## Direita: resumo da run (onda, almas, vida e todos os stats do pato e do poste).

signal resumed
## Sai para o menu mantendo o checkpoint (a run continua do início da onda atual).
signal quit_to_menu
signal abandon

var _resume: PixelButton
var _settings_button: PixelButton
var _controls_button: PixelButton
var _abandon: PixelButton
var _summary: VBoxContainer
var _root: Control

@onready var settings_panel: SettingsPanel = $SettingsPanel
@onready var controls_panel: ControlsPanel = $ControlsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	settings_panel.allow_reset = false
	settings_panel.closed.connect(func() -> void:
		_root.visible = true
		_settings_button.grab_focus())
	controls_panel.closed.connect(func() -> void:
		_root.visible = true
		_controls_button.grab_focus())


## `run`: {wave, souls, hp, stats: PlayerStats, pole: LightPole ou null}.
func open(run := {}) -> void:
	_fill_summary(run)
	visible = true
	_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and _root.visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	move_child(_root, 0)
	var dim := ColorRect.new()
	dim.color = UiStyle.DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(row)

	# --- Ações ---
	var actions := _panel(row, 150, "PAUSED")
	_resume = _button(actions, "RESUME", UiStyle.Variant.PRIMARY, close)
	_settings_button = _button(actions, "SETTINGS", UiStyle.Variant.SECONDARY, func() -> void:
		_root.visible = false
		settings_panel.open())
	_controls_button = _button(actions, "CONTROLS", UiStyle.Variant.SECONDARY, func() -> void:
		_root.visible = false
		controls_panel.open("BACK"))
	_button(actions, "SAVE & QUIT", UiStyle.Variant.SECONDARY, func() -> void: quit_to_menu.emit())
	_abandon = _button(actions, "ABANDON RUN", UiStyle.Variant.DANGER, _confirm_abandon)
	actions.add_child(UiStyle.spacer(2))
	var hint := UiStyle.label("YOUR RUN IS SAVED AT THE START OF EACH WAVE", UiStyle.FONT_SMALL, UiStyle.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(130, 0)
	actions.add_child(hint)
	# No navegador, ESC é usado para sair da tela cheia antes de chegar ao jogo.
	if OS.has_feature("web"):
		var web := UiStyle.label("ON THE WEB, ESC LEAVES FULLSCREEN - USE P TO PAUSE", UiStyle.FONT_SMALL, UiStyle.ACCENT)
		web.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		web.custom_minimum_size = Vector2(130, 0)
		actions.add_child(web)

	# --- Resumo da run ---
	_summary = _panel(row, 190, "THIS RUN")
	_summary.add_theme_constant_override(&"separation", 3)


func _panel(parent: Control, width: float, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", UiStyle.panel_box())
	panel.custom_minimum_size = Vector2(width, 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 5)
	panel.add_child(column)
	column.add_child(UiStyle.header(title))
	return column


func _button(parent: Control, text: String, variant: UiStyle.Variant, action: Callable) -> PixelButton:
	var node := UiStyle.button(text, variant, Vector2(130, 20))
	node.pressed.connect(action)
	parent.add_child(node)
	return node


func _fill_summary(run: Dictionary) -> void:
	# Mantém só o cabeçalho (primeiro filho) e remonta as linhas.
	for i in range(_summary.get_child_count() - 1, 0, -1):
		_summary.get_child(i).queue_free()
	if run.is_empty():
		return
	var stats: PlayerStats = run.stats
	_add(UiStyle.stat_row("crown", "WAVE", "%02d" % run.wave))
	_add(UiStyle.stat_row("soul", "SOULS", str(run.souls), UiStyle.SOUL))
	_add(UiStyle.stat_row("heart", "HEALTH", "%d/%d" % [ceili(run.hp), roundi(stats.max_hp)], UiStyle.DANGER_HI))
	_add(UiStyle.separator())
	_add(UiStyle.stat_row("damage", "DAMAGE", str(roundi(stats.projectile_damage))))
	_add(UiStyle.stat_row("crit", "CRITICAL", "%d%%" % roundi(stats.crit_chance)))
	_add(UiStyle.stat_row("rate", "SHOTS/S", "%.1f" % (stats.attack_speed * (1.0 + stats.attack_speed_bonus / 100.0))))
	_add(UiStyle.stat_row("shield", "DEFENSE", "%d%%" % roundi(stats.defense)))
	_add(UiStyle.stat_row("speed", "SPEED", str(roundi(stats.move_speed))))
	_add(UiStyle.stat_row("jump", "JUMP HEIGHT", "+%d%%" % roundi(stats.jump_height_bonus)))
	var pole: LightPole = run.get("pole")
	if pole and is_instance_valid(pole):
		_add(UiStyle.separator())
		_add(UiStyle.stat_row("lamp", "POLE", tr("%d DMG x%d") % [roundi(pole.damage), pole.lasers], UiStyle.GOLD_HI))
		_add(UiStyle.stat_row("", "EVERY", "%.1fs" % pole.burst_interval()))


func _add(node: Control) -> void:
	_summary.add_child(node)


func _confirm_abandon() -> void:
	var dialog := ConfirmDialog.ask(self, tr("ABANDON RUN?"),
		tr("THE RUN ENDS NOW. YOU KEEP THE SOULS AND THE RECORD."), "ABANDON RUN", true)
	dialog.confirmed.connect(func() -> void: abandon.emit())
	dialog.cancelled.connect(_abandon.grab_focus)
