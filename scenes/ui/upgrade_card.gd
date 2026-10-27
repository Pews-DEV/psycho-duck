class_name UpgradeCard
extends Control
## Carta de pergaminho: nome no topo, ícone no quadro, texto do efeito e selo de raridade.
## A arte é ampliada em 2×; os textos ficam na fonte de 8 px (nítida).
## No hover a carta sobe alguns pixels (sem escala, para não distorcer a pixel art).

signal chosen(card: UpgradeCard)

const BACKGROUND := preload("res://assets/ui/upgrade-background.png")
const INK := Color("45293f")
const PARCHMENT := Color("c09473")
## Ampliação da arte da carta (41×62 → 82×124).
const ART_SCALE := 2
const SIZE := Vector2(41, 62) * ART_SCALE
const LIFT := 5.0
## Cor do selo por raridade: [fundo, texto].
const RARITY_TAGS := [[UiStyle.STEEL, UiStyle.INK], [UiStyle.RARE, UiStyle.TEXT], [UiStyle.EPIC, UiStyle.TEXT]]

var upgrade: UpgradeData
var rarity: UpgradeData.Rarity = UpgradeData.Rarity.COMMON
## Etiqueta no lugar da raridade (ex.: "NEW" na carta em destaque da loja).
var tag := ""
## Tecla de atalho mostrada no canto ("1".."4"); vazio = sem tecla.
var hotkey := ""

var _body: Control


func setup(data: UpgradeData, card_rarity: UpgradeData.Rarity) -> void:
	upgrade = data
	rarity = card_rarity


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_body = Control.new()
	_body.size = SIZE
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_add_art(BACKGROUND, Vector2.ZERO)
	_add_art(upgrade.icon, Vector2(6, 11) * ART_SCALE)

	# Nomes longos passam por cima do rolo escuro do pergaminho: contorno claro para ler.
	var title := _add_label(tr(upgrade.display_name).to_upper(), Rect2(4, 4, 74, 12), INK)
	title.add_theme_color_override(&"font_outline_color", PARCHMENT)
	title.add_theme_constant_override(&"outline_size", 3)
	var description := _add_label(upgrade.describe(rarity), Rect2(10, 63, 62, 38), INK, true)
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	var footer_text := ""
	var footer_colors: Array = []
	if tag != "":
		footer_text = tag
		footer_colors = [UiStyle.GOLD, UiStyle.INK]
	elif upgrade.permanent:
		footer_text = UpgradeData.PERMANENT_NAME
		footer_colors = [UiStyle.GOLD, UiStyle.INK]
	elif upgrade.has_rarity:
		footer_text = UpgradeData.RARITY_NAMES[rarity]
		footer_colors = RARITY_TAGS[rarity]
	if footer_text != "":
		var seal := PanelContainer.new()
		seal.add_theme_stylebox_override(&"panel", UiStyle.tag_box(footer_colors[0], 2))
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.add_child(UiStyle.label(footer_text, UiStyle.FONT_SMALL, footer_colors[1]))
		_body.add_child(seal)
		seal.reset_size()
		seal.position = Vector2(roundf((SIZE.x - seal.size.x) / 2.0), 104)

	# Tecla no canto de baixo (em cima ficaria sobre o nome).
	if hotkey != "":
		var key := UiStyle.key_cap(hotkey)
		_body.add_child(key)
		key.reset_size()
		key.position = Vector2(-3, SIZE.y - key.size.y + 2)

	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		chosen.emit(self)


func _add_art(texture: Texture2D, at: Vector2) -> void:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.position = at
	art.size = texture.get_size() * ART_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.add_child(art)


func _add_label(text: String, rect: Rect2, color: Color, wrap := false) -> Label:
	var label := UiStyle.label(text, UiStyle.FONT_SMALL, color)
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	label.clip_text = not wrap
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body.add_child(label)
	# Posição e tamanho depois do add_child, senão o Label volta ao tamanho mínimo do texto.
	label.position = rect.position
	label.size = rect.size
	return label


func _set_hover(hovered: bool) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(_body, "position:y", -LIFT if hovered else 0.0, 0.08)
	tween.tween_property(_body, "modulate", Color(1.12, 1.08, 1.0) if hovered else Color.WHITE, 0.08)
	if hovered:
		Sfx.play(&"ui_hover", -10.0, 0.0)
