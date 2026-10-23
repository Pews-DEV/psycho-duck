class_name MetaShop
extends CanvasLayer
## Loja permanente (menu): gasta as almas acumuladas entre runs em melhorias por níveis.

signal closed

const SOUL_ICON := preload("res://assets/ui/point.png")
const ENTRY_SIZE := Vector2(148, 64)
const COLUMNS := 3

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
	var column := UiStyle.centered_panel(self, 470)
	column.add_theme_constant_override(&"separation", 6)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := UiStyle.label("PERMANENT UPGRADES", 12, UiStyle.ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_souls_label = UiStyle.label("0", 12, UiStyle.BORDER, HORIZONTAL_ALIGNMENT_RIGHT)
	header.add_child(_souls_label)
	header.add_child(_soul_icon())

	var hint := UiStyle.label("SPEND SOULS FROM PAST RUNS. BONUSES APPLY TO EVERY RUN.", 7, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	column.add_child(hint)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", 6)
	_grid.add_theme_constant_override(&"v_separation", 6)
	column.add_child(_grid)

	_back = UiStyle.button("BACK")
	_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_back.pressed.connect(close)
	column.add_child(_back)


func _refresh() -> void:
	_souls_label.text = str(GameState.souls)
	for child in _grid.get_children():
		child.queue_free()
	for upgrade in GameState.META_UPGRADES:
		_grid.add_child(_entry(upgrade))


## Uma melhoria: ícone, nome, efeito do próximo nível, nível atual e preço. Clique compra.
func _entry(upgrade: MetaUpgrade) -> Button:
	var level := GameState.meta_level(upgrade)
	var maxed := level >= upgrade.max_level
	var price := upgrade.cost_for(level)
	var affordable := not maxed and GameState.souls >= price

	var entry := Button.new()
	entry.custom_minimum_size = ENTRY_SIZE
	entry.focus_mode = Control.FOCUS_ALL
	var normal := UiStyle.panel_box(UiStyle.ACCENT if maxed else Color("5d4a5e"), 4)
	var hover := UiStyle.panel_box(UiStyle.ACCENT if affordable else Color("8a7a8c"), 4)
	for state in [&"normal", &"disabled"]:
		entry.add_theme_stylebox_override(state, normal)
	for state in [&"hover", &"pressed", &"focus"]:
		entry.add_theme_stylebox_override(state, hover)
	entry.pressed.connect(_buy.bind(upgrade, entry))

	var icon := TextureRect.new()
	icon.texture = upgrade.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.position = Vector2(5, 13)
	icon.size = upgrade.icon.get_size() * 2
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(icon)

	_place(entry, UiStyle.label(upgrade.display_name, 8, UiStyle.BORDER, HORIZONTAL_ALIGNMENT_LEFT), Rect2(66, 4, 80, 12))
	var description := UiStyle.label(upgrade.describe(level if maxed else level + 1), 6, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(entry, description, Rect2(66, 17, 80, 26))
	_place(entry, UiStyle.label(tr("LV %d/%d") % [level, upgrade.max_level], 7, UiStyle.BORDER, HORIZONTAL_ALIGNMENT_LEFT), Rect2(66, 47, 40, 12))

	if maxed:
		_place(entry, UiStyle.label("MAX", 8, UiStyle.ACCENT, HORIZONTAL_ALIGNMENT_RIGHT), Rect2(100, 46, 44, 12))
	else:
		var price_label := UiStyle.label(str(price), 8, UiStyle.BORDER if affordable else Color("e83b3b"), HORIZONTAL_ALIGNMENT_RIGHT)
		_place(entry, price_label, Rect2(96, 46, 30, 12))
		var soul := _soul_icon()
		soul.position = Vector2(128, 47)
		soul.size = Vector2(15, 10)
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
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.clip_text = node.autowrap_mode == TextServer.AUTOWRAP_OFF
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size


func _soul_icon() -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = SOUL_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(20, 14)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon
