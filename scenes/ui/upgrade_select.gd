extends CanvasLayer
## Pausa o jogo e mostra 4 cartas de upgrade no início de cada onda.
## Cabeçalho com a onda, cartas com a tecla de atalho no canto e dica embaixo.

signal upgrade_chosen(upgrade: UpgradeData, rarity: UpgradeData.Rarity)

const CARD_COUNT := 4
const CARD_GAP := 16
const CARDS_Y := 74.0

@export var upgrades: Array[UpgradeData] = []

var cards_root: Control
var _wave_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.INK, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var head := VBoxContainer.new()
	head.add_theme_constant_override(&"separation", 0)
	head.position = Vector2(0, 26)
	head.size = Vector2(View.SIZE.x, 30)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	_wave_label = UiStyle.label("", UiStyle.FONT_LARGE, UiStyle.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, true)
	_wave_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	head.add_child(_wave_label)
	head.add_child(UiStyle.label("CHOOSE AN UPGRADE", UiStyle.FONT_SMALL, UiStyle.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true))

	cards_root = Control.new()
	cards_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	cards_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cards_root)

	var hint := UiStyle.hint_row(["1-4", "OR CLICK A CARD"])
	hint.position = Vector2(0, 214)
	hint.size = Vector2(View.SIZE.x, 14)
	add_child(hint)


func open(wave: int) -> void:
	for child in cards_root.get_children():
		child.queue_free()
	_wave_label.text = tr("WAVE %02d") % wave

	var pool := upgrades.duplicate()
	pool.shuffle()
	var picks := pool.slice(0, mini(CARD_COUNT, pool.size()))
	var card_width := UpgradeCard.SIZE.x
	var total := picks.size() * card_width + (picks.size() - 1) * CARD_GAP
	var start_x := roundf((View.SIZE.x - total) / 2.0)
	for i in picks.size():
		var card := UpgradeCard.new()
		card.setup(picks[i], UpgradeData.roll_rarity(wave))
		card.hotkey = str(i + 1)
		card.position = Vector2(start_x + i * (card_width + CARD_GAP), View.SIZE.y)
		card.chosen.connect(_on_card_chosen)
		cards_root.add_child(card)
		var tween := card.create_tween()
		tween.tween_interval(0.05 * i)
		tween.tween_property(card, "position:y", CARDS_Y, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Atalho: teclas 1-4 escolhem a carta.
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.physical_keycode - KEY_1
		if index >= 0 and index < cards_root.get_child_count():
			get_viewport().set_input_as_handled()
			_on_card_chosen(cards_root.get_child(index))


func _on_card_chosen(card: UpgradeCard) -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Sfx.play(&"card_pick", -3.0, 0.0)
	upgrade_chosen.emit(card.upgrade, card.rarity)
