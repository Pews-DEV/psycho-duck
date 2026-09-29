class_name UpgradeCard
extends Control
## Carta de pergaminho: nome no topo, ícone no quadro e texto do efeito.
## Desenhada em 2× (a arte é ampliada em pixel art; os textos usam fontes maiores).

signal chosen(card: UpgradeCard)

const BACKGROUND := preload("res://assets/ui/upgrade-background.png")
const INK := Color("3e2731")
## Ampliação da arte da carta (41×62 → 82×124).
const ART_SCALE := 2
const SIZE := Vector2(41, 62) * ART_SCALE

var upgrade: UpgradeData
var rarity: UpgradeData.Rarity = UpgradeData.Rarity.COMMON
## Etiqueta no lugar da raridade (ex.: "NEW" na carta em destaque da loja).
var tag := ""


func setup(data: UpgradeData, card_rarity: UpgradeData.Rarity) -> void:
	upgrade = data
	rarity = card_rarity


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = SIZE / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_add_art(BACKGROUND, Vector2.ZERO)
	_add_art(upgrade.icon, Vector2(6, 11) * ART_SCALE)

	var name_size := 8 if upgrade.display_name.length() <= 8 else 7
	_add_label(upgrade.display_name, Rect2(6, 3, 70, 14), name_size, INK)
	var description := _add_label(upgrade.describe(rarity), Rect2(7, 64, 68, 38), 7, INK, false, true)
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var footer := Rect2(6, 105, 70, 14)
	if tag != "":
		_add_label(tag, footer, 7, UpgradeData.PERMANENT_COLOR, true)
	elif upgrade.permanent:
		_add_label(UpgradeData.PERMANENT_NAME, footer, 7, UpgradeData.PERMANENT_COLOR, true)
	elif upgrade.has_rarity:
		_add_label(UpgradeData.RARITY_NAMES[rarity], footer, 7, UpgradeData.RARITY_COLORS[rarity], true)

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
	add_child(art)


func _add_label(text: String, rect: Rect2, font_size: int, color: Color, outlined := false, wrap := false) -> Label:
	var label := Label.new()
	label.text = text
	label.clip_text = not wrap
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_constant_override(&"line_spacing", 1)
	if outlined:
		label.add_theme_color_override(&"font_outline_color", INK)
		label.add_theme_constant_override(&"outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	# Posição e tamanho depois do add_child, senão o Label volta ao tamanho mínimo do texto.
	label.position = rect.position
	label.size = rect.size
	return label


func _set_hover(hovered: bool) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06) if hovered else Vector2.ONE, 0.08)
	tween.tween_property(self, "modulate", Color(1.15, 1.1, 1.0) if hovered else Color.WHITE, 0.08)
	if hovered:
		Sfx.play(&"ui_hover", -10.0, 0.0)
