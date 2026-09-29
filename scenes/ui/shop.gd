extends CanvasLayer
## Loja dentro da casinha, aberta a cada 5 ondas. Compra com as almas da run;
## o slot comprado fica vazio até recarregar. Às vezes aparece um item permanente.

signal souls_changed(souls: int)
signal purchased(upgrade: UpgradeData, rarity: UpgradeData.Rarity)
signal closed

const SLOT_COUNT := 4
const CARD_WIDTH := UpgradeCard.SIZE.x
const CARD_HEIGHT := UpgradeCard.SIZE.y
const CARD_GAP := 18.0
const CARDS_Y := 52.0
const COUNTER_Y := 198.0
## Preço por raridade na primeira visita (onda 5); sobe 40% a cada visita.
const PRICES := [10, 16, 26]
const PRICE_GROWTH := 0.4
## Chance de cada slot trazer um item permanente ainda não comprado.
const ITEM_CHANCE := 0.15
const REROLL_BASE_COST := 5
const REROLL_COST_STEP := 3
const SOUL_ICON := preload("res://assets/ui/point.png")
const PRICE_COLOR := Color("fbf5ef")
const EXPENSIVE_COLOR := Color("e83b3b")

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

@onready var background: ColorRect = $Background
@onready var subtitle: Label = $Subtitle
@onready var souls_label: Label = $SoulsLabel
@onready var slots_root: Control = $Slots
@onready var reroll_button: PixelButton = $Reroll
@onready var leave_button: PixelButton = $Leave


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	background.draw.connect(_draw_interior)
	reroll_button.pressed.connect(_reroll)
	leave_button.pressed.connect(close)


func open(current_souls: int, wave: int, shop_flags := {}) -> void:
	souls = current_souls
	_wave = wave
	flags = shop_flags
	_price_multiplier = 1.0 + maxf(floorf(wave / 5.0) - 1.0, 0.0) * PRICE_GROWTH
	_reroll_cost = REROLL_BASE_COST
	subtitle.text = "WAVE %02d CLEARED - SPEND YOUR SOULS" % wave
	_roll_offers()
	var featured := _featured_offers()
	if not featured.is_empty():
		subtitle.text = "NEW IN THE SHOP: %s" % ", ".join(featured.map(func(u: UpgradeData) -> String: return u.display_name.to_upper()))
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
	card.chosen.connect(func(_card: UpgradeCard) -> void: _buy(index))
	slot.add_child(card)

	var tag := HBoxContainer.new()
	tag.name = "PriceTag"
	tag.alignment = BoxContainer.ALIGNMENT_CENTER
	tag.add_theme_constant_override(&"separation", 4)
	tag.position = Vector2(0, CARD_HEIGHT + 4)
	tag.size = Vector2(CARD_WIDTH, 16)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var price := Label.new()
	price.name = "Price"
	price.text = str(offer.price)
	price.add_theme_font_size_override(&"font_size", 12)
	price.add_theme_color_override(&"font_outline_color", Color("2e222f"))
	price.add_theme_constant_override(&"outline_size", 4)
	tag.add_child(price)
	var icon := TextureRect.new()
	icon.texture = SOUL_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = SOUL_ICON.get_size() * 2
	tag.add_child(icon)
	slot.add_child(tag)
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
		var price: Label = _slot_nodes[i].get_node("PriceTag/Price")
		price.add_theme_color_override(&"font_color", PRICE_COLOR if souls >= offer.price else EXPENSIVE_COLOR)
	reroll_button.text = "REROLL %d" % _reroll_cost
	reroll_button.modulate = Color.WHITE if souls >= _reroll_cost else Color(1, 1, 1, 0.5)


func _shake(node: Control) -> void:
	var origin := node.position.x
	var tween := node.create_tween()
	for offset in [3.0, -3.0, 2.0, -2.0, 0.0]:
		tween.tween_property(node, "position:x", origin + offset, 0.04)


func _draw_empty_slot(empty: Control) -> void:
	var color := Color(0.98, 0.96, 0.94, 0.25)
	var rect := Rect2(Vector2(4, 4), empty.size - Vector2(8, 8))
	# Contorno tracejado: pedaços de 5 px com 3 px de espaço.
	for x in range(int(rect.position.x), int(rect.end.x), 8):
		empty.draw_rect(Rect2(x, rect.position.y, 5, 2), color)
		empty.draw_rect(Rect2(x, rect.end.y - 2, 5, 2), color)
	for y in range(int(rect.position.y), int(rect.end.y), 8):
		empty.draw_rect(Rect2(rect.position.x, y, 2, 5), color)
		empty.draw_rect(Rect2(rect.end.x - 2, y, 2, 5), color)
	var font := empty.get_theme_default_font()
	empty.draw_string(font, Vector2(0, empty.size.y / 2.0 + 4), "SOLD", HORIZONTAL_ALIGNMENT_CENTER, empty.size.x, 10, color)


## Interior da casinha: tábuas na parede e um balcão embaixo.
func _draw_interior() -> void:
	var size := background.size
	for y in range(0, int(size.y), 16):
		background.draw_rect(Rect2(0, y, size.x, 1), Color("4a2a33"))
		var shift := 48 if int(y / 16.0) % 2 == 0 else 0
		for x in range(shift, int(size.x), 96):
			background.draw_rect(Rect2(x, y, 1, 16), Color("4a2a33"))
	background.draw_rect(Rect2(0, COUNTER_Y, size.x, 4), Color("c86a3d"))
	background.draw_rect(Rect2(0, COUNTER_Y + 4, size.x, size.y - COUNTER_Y - 4), Color("5d2c28"))
	background.draw_rect(Rect2(0, COUNTER_Y + 4, size.x, 1), Color("3e1f22"))
