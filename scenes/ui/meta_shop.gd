class_name MetaShop
extends CanvasLayer
## Loja permanente (menu): gasta as almas acumuladas entre runs em melhorias por níveis.
## Grade 2×3; cada entrada mostra ícone, nome, efeito do próximo nível, nível e preço.

signal closed

const ENTRY_SIZE := Vector2(208, 48)
const COLUMNS := 2
const TEXT_X := 66.0
const TEXT_WIDTH := 136.0

var _souls_label: Label
var _grid: GridContainer
var _back: PixelButton


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	_refresh()
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
	var column := UiStyle.centered_panel(self, 440, "PERMANENT UPGRADES")
	column.add_theme_constant_override(&"separation", 5)

	var info := HBoxContainer.new()
	info.add_theme_constant_override(&"separation", 4)
	column.add_child(info)
	var hint := UiStyle.label("BONUSES APPLY TO EVERY RUN.", UiStyle.FONT_SMALL, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(hint)
	var wallet := PanelContainer.new()
	wallet.add_theme_stylebox_override(&"panel", UiStyle.tag_box(UiStyle.INK, 3))
	info.add_child(wallet)
	var wallet_row := HBoxContainer.new()
	wallet_row.add_theme_constant_override(&"separation", 3)
	wallet.add_child(wallet_row)
	_souls_label = UiStyle.label("0", UiStyle.FONT_SMALL, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	_souls_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	wallet_row.add_child(_souls_label)
	wallet_row.add_child(UiStyle.soul_icon())

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", 4)
	_grid.add_theme_constant_override(&"v_separation", 4)
	column.add_child(_grid)

	_back = UiStyle.button("BACK", UiStyle.Variant.PRIMARY)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	column.add_child(_back)


func _refresh() -> void:
	_souls_label.text = str(GameState.souls)
	for child in _grid.get_children():
		child.queue_free()
	for upgrade in GameState.META_UPGRADES:
		_grid.add_child(_entry(upgrade))


## Uma melhoria. Clique compra o próximo nível.
func _entry(upgrade: MetaUpgrade) -> Button:
	var level := GameState.meta_level(upgrade)
	var maxed := level >= upgrade.max_level
	var price := upgrade.cost_for(level)
	var affordable := not maxed and GameState.souls >= price

	var entry := Button.new()
	entry.custom_minimum_size = ENTRY_SIZE
	entry.focus_mode = Control.FOCUS_ALL
	var ring := UiStyle.ACCENT if affordable or maxed else UiStyle.LINE
	for state in [&"normal", &"disabled"]:
		entry.add_theme_stylebox_override(state, UiStyle.inset_box(UiStyle.ACCENT if maxed else Color.TRANSPARENT))
	for state in [&"hover", &"pressed", &"focus", &"hover_pressed"]:
		entry.add_theme_stylebox_override(state, UiStyle.inset_box(ring))
	entry.pressed.connect(_buy.bind(upgrade, entry))
	entry.mouse_entered.connect(func() -> void:
		entry.grab_focus()
		Sfx.play(&"ui_hover", -10.0, 0.0))

	var icon := TextureRect.new()
	icon.texture = upgrade.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.position = Vector2(5, 5)
	icon.size = upgrade.icon.get_size() * 2
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not affordable and not maxed:
		icon.modulate = Color(0.75, 0.72, 0.8)
	entry.add_child(icon)

	_place(entry, UiStyle.label(tr(upgrade.display_name).to_upper(), UiStyle.FONT_SMALL, UiStyle.ACCENT if maxed else UiStyle.TEXT, HORIZONTAL_ALIGNMENT_LEFT), Rect2(TEXT_X, 3, TEXT_WIDTH, 11))
	var description := UiStyle.label(upgrade.describe(level if maxed else level + 1), UiStyle.FONT_SMALL, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(entry, description, Rect2(TEXT_X, 13, TEXT_WIDTH, 20))

	var pips := Control.new()
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pips.position = Vector2(TEXT_X + 1, 38)
	pips.size = Vector2(upgrade.max_level * 6, 5)
	pips.draw.connect(func() -> void:
		for i in upgrade.max_level:
			pips.draw_rect(Rect2(i * 6 - 1, -1, 6, 6), UiStyle.INK)
			pips.draw_rect(Rect2(i * 6, 0, 4, 4), UiStyle.ACCENT if i < level else UiStyle.SURFACE_HI))
	entry.add_child(pips)

	if maxed:
		_place(entry, UiStyle.label("MAX", UiStyle.FONT_SMALL, UiStyle.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT), Rect2(150, 34, 52, 11))
	else:
		var price_label := UiStyle.label(str(price), UiStyle.FONT_SMALL, UiStyle.TEXT if affordable else UiStyle.DANGER, HORIZONTAL_ALIGNMENT_RIGHT)
		price_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_place(entry, price_label, Rect2(150, 34, 40, 11))
		var soul := UiStyle.soul_icon()
		soul.position = Vector2(193, 34)
		soul.size = Vector2(10, 11)
		entry.add_child(soul)
	return entry


func _buy(upgrade: MetaUpgrade, entry: Control) -> void:
	if GameState.buy_meta(upgrade):
		Sfx.play(&"buy", -3.0, 0.0)
		_refresh()
		# Mantém o foco na mesma posição da grade para quem usa teclado.
		var index := GameState.META_UPGRADES.find(upgrade)
		await get_tree().process_frame
		if index >= 0 and index < _grid.get_child_count():
			(_grid.get_child(index) as Control).grab_focus()
	else:
		Sfx.play(&"deny", -4.0, 0.0)
		var origin := entry.position.x
		var tween := entry.create_tween()
		for offset in [3.0, -3.0, 2.0, 0.0]:
			tween.tween_property(entry, "position:x", origin + offset, 0.04)


func _place(parent: Control, node: Label, rect: Rect2) -> void:
	node.clip_text = node.autowrap_mode == TextServer.AUTOWRAP_OFF
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
