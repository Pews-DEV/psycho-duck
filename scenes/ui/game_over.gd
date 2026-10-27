extends CanvasLayer
## Fim da run: onda alcançada, recorde, almas ganhas e o que falta para a próxima skin.

signal retry
signal quit_to_menu

var _column: VBoxContainer
var _rows: VBoxContainer
var _record: PanelContainer
var _retry: PixelButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_column = UiStyle.centered_panel(self, 240, "GAME OVER", UiStyle.DANGER_LO)
	(_column.get_child(0).get_child(0) as Label).add_theme_color_override(&"font_color", UiStyle.DANGER)
	_column.add_theme_constant_override(&"separation", 6)

	_record = PanelContainer.new()
	_record.add_theme_stylebox_override(&"panel", UiStyle.tag_box(UiStyle.GOLD, 3))
	_record.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_record.add_child(UiStyle.label("NEW RECORD!", UiStyle.FONT_SMALL, UiStyle.INK))
	_column.add_child(_record)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override(&"separation", 3)
	_column.add_child(_rows)

	_column.add_child(UiStyle.spacer(2))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 8)
	_column.add_child(buttons)
	var menu := UiStyle.button("MENU", UiStyle.Variant.SECONDARY, Vector2(100, 20))
	menu.pressed.connect(func() -> void: quit_to_menu.emit())
	buttons.add_child(menu)
	_retry = UiStyle.button("RETRY", UiStyle.Variant.PRIMARY, Vector2(100, 20))
	_retry.pressed.connect(func() -> void: retry.emit())
	buttons.add_child(_retry)


func open(wave: int, souls: int, is_record: bool) -> void:
	for child in _rows.get_children():
		child.queue_free()
	_record.visible = is_record
	_rows.add_child(UiStyle.stat_row("crown", "WAVE REACHED", "%02d" % wave))
	_rows.add_child(UiStyle.stat_row("", "BEST", "%02d" % GameState.best_wave, UiStyle.ACCENT if is_record else UiStyle.TEXT))
	_rows.add_child(UiStyle.separator())
	_rows.add_child(UiStyle.stat_row("soul", "SOULS EARNED", "+%d" % souls, UiStyle.SOUL))
	_rows.add_child(UiStyle.stat_row("", "TOTAL SOULS", str(GameState.souls)))
	var next_skin := _next_locked_skin()
	if next_skin:
		_rows.add_child(UiStyle.separator())
		_rows.add_child(UiStyle.stat_row("lock", "NEXT SKIN", tr("WAVE %02d") % next_skin.unlock_wave, UiStyle.MUTED))
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_retry.grab_focus()


func _next_locked_skin() -> SkinData:
	for i in GameState.SKINS.size():
		if not GameState.is_skin_unlocked(i):
			return GameState.SKINS[i]
	return null
