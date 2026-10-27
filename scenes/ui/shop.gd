extends CanvasLayer
## Loja dentro da casinha, aberta a cada 5 ondas. Compra com as almas da run;
## o slot comprado fica vazio até recarregar. Às vezes aparece um item permanente.

signal souls_changed(souls: int)
signal purchased(upgrade: UpgradeData, rarity: UpgradeData.Rarity)
signal closed

const SLOT_COUNT := 4
const CARD_WIDTH := UpgradeCard.SIZE.x
const CARD_HEIGHT := UpgradeCard.SIZE.y
const CARD_GAP := 16.0
const CARDS_Y := 46.0
const COUNTER_Y := 196.0
## Preço por raridade na primeira visita (onda 5); sobe 40% a cada visita.
const PRICES := [10, 16, 26]
const PRICE_GROWTH := 0.4
## Chance de cada slot trazer um item permanente ainda não comprado.
const ITEM_CHANCE := 0.15
const REROLL_BASE_COST := 5
const REROLL_COST_STEP := 3
const PRICE_COLOR := UiStyle.TEXT
const EXPENSIVE_COLOR := UiStyle.DANGER

@export var upgrades: Array[UpgradeData] = []
## Categorias liberadas por onda (a primeira é o poste de luz, na onda 10).
@export var categories: Array[ShopCategory] = []

## Condições informadas pelo jogo, usadas em UpgradeData.requires (ex.: "pole_built").
var flags := {}

var souls := 0

## Uma oferta por slot: {upgrade, rarity, price}, ou null quando vendida.
var _offers: Array = []
var _slot_nodes: Array[Control] = []
var _price_multiplier := 1.0
var _reroll_cost := REROLL_BASE_COST
var _wave := 1

var subtitle: Label
var souls_label: Label
var reroll_button: PixelButton
var leave_button: PixelButton

@onready var background: ColorRect = $Background
@onready var slots_root: Control = $Slots


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	background.draw.connect(_draw_interior)
	_build()


## Cabeçalho, carteira de almas, botões no balcão e dica de teclas.
func _build() -> void:
	var head := VBoxContainer.new()
	head.add_theme_constant_override(&"separation", 0)
	head.position = Vector2(0, 6)
	head.size = Vector2(View.SIZE.x, 32)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	head.add_child(UiStyle.label("SHOP", UiStyle.FONT_LARGE, UiStyle.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, true))
	subtitle = UiStyle.label("", UiStyle.FONT_SMALL, UiStyle.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	subtitle.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	head.add_child(subtitle)

	var wallet := PanelContainer.new()
	wallet.add_theme_stylebox_override(&"panel", UiStyle.tag_box(UiStyle.INK, 4))
	add_child(wallet)
	var wallet_row := HBoxContainer.new()
	wallet_row.add_theme_constant_override(&"separation", 3)
	wallet.add_child(wallet_row)
	souls_label = UiStyle.label("0", UiStyle.FONT_SMALL, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	souls_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	souls_label.custom_minimum_size = Vector2(24, 0)
	wallet_row.add_child(souls_label)
	wallet_row.add_child(UiStyle.soul_icon())
	wallet.position = Vector2(View.SIZE.x - 62, 8)
	wallet.custom_minimum_size = Vector2(54, 0)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 12)
	buttons.position = Vector2(0, COUNTER_Y + 14)
	buttons.size = Vector2(View.SIZE.x, 20)
	add_child(buttons)
	reroll_button = UiStyle.button("", UiStyle.Variant.SECONDARY, Vector2(120, 20))
	reroll_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	reroll_button.pressed.connect(_reroll)
	buttons.add_child(reroll_button)
	leave_button = UiStyle.button("LEAVE", UiStyle.Variant.PRIMARY, Vector2(120, 20))
	leave_button.pressed.connect(close)
	buttons.add_child(leave_button)

	var hint := UiStyle.hint_row(["1-4", "BUY", "R", "REROLL", "ESC", "LEAVE"])
	hint.position = Vector2(0, View.SIZE.y - 22)
	hint.size = Vector2(View.SIZE.x, 14)
	add_child(hint)


func open(current_souls: int, wave: int, shop_flags := {}) -> void:
	souls = current_souls
	_wave = wave
	flags = shop_flags
	_price_multiplier = 1.0 + maxf(floorf(wave / 5.0) - 1.0, 0.0) * PRICE_GROWTH
	_reroll_cost = REROLL_BASE_COST
	subtitle.text = tr("WAVE %02d CLEARED - SPEND YOUR SOULS") % wave
	_roll_offers()
	var featured := _featured_offers()
	if not featured.is_empty():
		subtitle.text = tr("NEW IN THE SHOP: %s") % ", ".join(featured.map(func(u: UpgradeData) -> String: return tr(u.display_name).to_upper()))
	_refresh()
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	leave_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	for node in _slot_nodes:
		node.queue_free()
	_slot_nodes.clear()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			get_viewport().set_input_as_handled()
			_reroll()
		var index: int = event.physical_keycode - KEY_1
		if index >= 0 and index < SLOT_COUNT:
			get_viewport().set_input_as_handled()
			_buy(index)


## Atualiza as condições (ex.: depois de construir o poste) para os próximos sorteios.
func set_flags(shop_flags: Dictionary) -> void:
	flags = shop_flags


func _eligible(upgrade: UpgradeData) -> bool:
	return upgrade.requires == &"" or flags.get(String(upgrade.requires), false)


## Cartas em destaque das categorias liberadas (ex.: construir o poste), ainda disponíveis.
func _featured_offers() -> Array:
	var featured := []
	for category in categories:
		if category.unlock_wave <= _wave and category.featured and _eligible(category.featured):
			featured.append(category.featured)
	return featured


func _price_for(upgrade: UpgradeData, rarity: int) -> int:
	if upgrade.shop_price > 0:
		return upgrade.shop_price
	return roundi(PRICES[rarity] * _price_multiplier)


func _roll_offers() -> void:
	var pool: Array = upgrades.duplicate()
	for category in categories:
		if category.unlock_wave > _wave:
			continue
		for offer in category.offers:
			if offer != category.featured and _eligible(offer):
				pool.append(offer)
	pool.shuffle()
	var featured := _featured_offers()
	var locked := GameState.get_locked_items()
	_offers.clear()
	for i in SLOT_COUNT:
		if i < featured.size():
			var card: UpgradeData = featured[i]
			_offers.append({"upgrade": card, "rarity": UpgradeData.Rarity.COMMON, "price": _price_for(card, 0), "tag": "NEW"})
		elif not locked.is_empty() and randf() < ITEM_CHANCE:
			var item: UpgradeData = locked.pick_random()
			locked.erase(item)
			_offers.append({"upgrade": item, "rarity": UpgradeData.Rarity.COMMON, "price": item.price})
		else:
			var upgrade: UpgradeData = pool.pop_back()
			var rarity := UpgradeData.roll_rarity(_wave) if upgrade.has_rarity else UpgradeData.Rarity.COMMON
			_offers.append({"upgrade": upgrade, "rarity": rarity, "price": _price_for(upgrade, rarity)})
	for node in _slot_nodes:
		node.queue_free()
	_slot_nodes.clear()
	for i in SLOT_COUNT:
		var slot := _build_slot(i)
		_slot_nodes.append(slot)
		slot.position.y = View.SIZE.y
		var tween := slot.create_tween()
		tween.tween_interval(0.05 * i)
		tween.tween_property(slot, "position:y", CARDS_Y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _slot_x(index: int) -> float:
	var total := SLOT_COUNT * CARD_WIDTH + (SLOT_COUNT - 1) * CARD_GAP
	return (View.SIZE.x - total) / 2.0 + index * (CARD_WIDTH + CARD_GAP)


## Um slot é a carta com a etiqueta de preço embaixo, ou um espaço vazio.
func _build_slot(index: int) -> Control:
	var slot := Control.new()
	slot.position = Vector2(_slot_x(index), CARDS_Y)
	slot.size = Vector2(CARD_WIDTH, CARD_HEIGHT + 20)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots_root.add_child(slot)

	var offer = _offers[index]
	if offer == null:
		var empty := Control.new()
		empty.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.draw.connect(_draw_empty_slot.bind(empty))
		slot.add_child(empty)
		return slot

	var card := UpgradeCard.new()
	card.setup(offer.upgrade, offer.rarity)
	card.tag = offer.get("tag", "")
	card.hotkey = str(index + 1)
	card.chosen.connect(func(_card: UpgradeCard) -> void: _buy(index))
	slot.add_child(card)

	# Etiqueta de preço pendurada embaixo da carta.
	var tag := PanelContainer.new()
	tag.name = "PriceTag"
	tag.add_theme_stylebox_override(&"panel", UiStyle.tag_box(UiStyle.INK, 3))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override(&"separation", 3)
	tag.add_child(tag_row)
	var price := UiStyle.label(str(offer.price), UiStyle.FONT_SMALL, PRICE_COLOR)
	price.name = "Price"
	price.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	tag_row.add_child(price)
	tag_row.add_child(UiStyle.soul_icon())
	slot.add_child(tag)
	tag.reset_size()
	tag.position = Vector2(roundf((CARD_WIDTH - tag.size.x) / 2.0), CARD_HEIGHT + 3)
	return slot


func _buy(index: int) -> void:
	var offer = _offers[index]
	if offer == null:
		return
	var slot := _slot_nodes[index]
	if souls < offer.price:
		_shake(slot)
		Sfx.play(&"deny", -4.0, 0.0)
		return
	souls -= offer.price
	souls_changed.emit(souls)
	if offer.upgrade.permanent:
		GameState.unlock(offer.upgrade)
	purchased.emit(offer.upgrade, offer.rarity)
	_offers[index] = null
	Sfx.play(&"buy", -3.0, 0.0)

	# A carta sobe e some; no lugar fica o slot vazio.
	var sold := _build_slot(index)
	sold.position.y = CARDS_Y
	_slot_nodes[index] = sold
	slots_root.move_child(slot, -1)
	var tween := slot.create_tween().set_parallel()
	tween.tween_property(slot, "position:y", CARDS_Y - 24.0, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(slot.queue_free)
	_refresh()


func _reroll() -> void:
	if souls < _reroll_cost:
		_shake(reroll_button)
		Sfx.play(&"deny", -4.0, 0.0)
		return
	souls -= _reroll_cost
	souls_changed.emit(souls)
	_reroll_cost += REROLL_COST_STEP
	Sfx.play(&"reroll", -3.0, 0.0)
	_roll_offers()
	_refresh()


func _refresh() -> void:
	souls_label.text = str(souls)
	for i in SLOT_COUNT:
		var offer = _offers[i]
		if offer == null or i >= _slot_nodes.size():
			continue
		var price: Label = _slot_nodes[i].get_node("PriceTag").find_child("Price", true, false)
		price.add_theme_color_override(&"font_color", PRICE_COLOR if souls >= offer.price else EXPENSIVE_COLOR)
	reroll_button.text = tr("REROLL %d") % _reroll_cost
	reroll_button.add_theme_color_override(&"font_color", UiStyle.TEXT if souls >= _reroll_cost else UiStyle.DANGER_HI)


func _shake(node: Control) -> void:
	var origin := node.position.x
	var tween := node.create_tween()
	for offset in [3.0, -3.0, 2.0, -2.0, 0.0]:
		tween.tween_property(node, "position:x", origin + offset, 0.04)


func _draw_empty_slot(empty: Control) -> void:
	var color := Color(UiStyle.MUTED, 0.3)
	var rect := Rect2(Vector2(4, 4), empty.size - Vector2(8, 8))
	# Contorno tracejado: pedaços de 5 px com 3 px de espaço.
	for x in range(int(rect.position.x), int(rect.end.x), 8):
		empty.draw_rect(Rect2(x, rect.position.y, 5, 2), color)
		empty.draw_rect(Rect2(x, rect.end.y - 2, 5, 2), color)
	for y in range(int(rect.position.y), int(rect.end.y), 8):
		empty.draw_rect(Rect2(rect.position.x, y, 2, 5), color)
		empty.draw_rect(Rect2(rect.end.x - 2, y, 2, 5), color)
	var font := empty.get_theme_default_font()
	empty.draw_string(font, Vector2(0, empty.size.y / 2.0 + 4), tr("SOLD"), HORIZONTAL_ALIGNMENT_CENTER, empty.size.x, UiStyle.FONT_SMALL, color)


## Interior da casinha: tábuas na parede e um balcão de madeira embaixo.
func _draw_interior() -> void:
	var size := background.size
	var plank := Color(UiStyle.INK, 0.55)
	for y in range(0, int(COUNTER_Y), 16):
		background.draw_rect(Rect2(0, y, size.x, 1), plank)
		var shift := 48 if int(y / 16.0) % 2 == 0 else 0
		for x in range(shift, int(size.x), 96):
			background.draw_rect(Rect2(x, y, 1, 16), plank)
	background.draw_rect(Rect2(0, COUNTER_Y - 1, size.x, 1), UiStyle.INK)
	background.draw_rect(Rect2(0, COUNTER_Y, size.x, 1), Color("e6904e"))
	background.draw_rect(Rect2(0, COUNTER_Y + 1, size.x, 3), Color("cd683d"))
	background.draw_rect(Rect2(0, COUNTER_Y + 4, size.x, size.y - COUNTER_Y - 4), Color("9e4539"))
	background.draw_rect(Rect2(0, COUNTER_Y + 4, size.x, 1), Color("6e2727"))
	for x in range(24, int(size.x), 48):
		background.draw_rect(Rect2(x, COUNTER_Y + 5, 1, size.y - COUNTER_Y - 5), Color(Color("6e2727"), 0.6))
