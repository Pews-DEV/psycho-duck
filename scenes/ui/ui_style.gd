class_name UiStyle
extends RefCounted
## Sistema visual da interface: paleta, tamanhos de fonte, molduras em pixel art (9-slice),
## botões, ícones pequenos, barras e teclas. Toda tela nova deve montar suas peças daqui.
## Referência completa em docs/DESIGN.md (seção Interface).

# --- Paleta (Resurrect 64) ------------------------------------------------------
const INK := Color("2e222f")
const PLUM := Color("45293f")
const SURFACE := Color("3e3546")
const SURFACE_HI := Color("625565")
const LINE := Color("7f708a")
const STEEL := Color("9babb2")
const TEXT := Color("ffffff")
const MUTED := Color("c7dcd0")
const ACCENT := Color("fbb954")
const GOLD := Color("f9c22b")
const GOLD_HI := Color("fbff86")
const GOLD_LO := Color("f79617")
const DANGER := Color("e83b3b")
const DANGER_HI := Color("f68181")
const DANGER_LO := Color("ae2334")
const DANGER_DARK := Color("6e2727")
const HEAL := Color("1ebc73")
const SOUL := Color("8fd3ff")
const RARE := Color("4d9be6")
const EPIC := Color("a884f3")
## Fundo escurecido atrás dos painéis.
const DIM := Color(0.1, 0.07, 0.12, 0.78)

# --- Fonte (Silkscreen só fica nítida em múltiplos de 8) ---------------------------
const FONT_SMALL := 8
const FONT_LARGE := 16
const FONT_HUGE := 32

enum Variant { SECONDARY, PRIMARY, DANGER }

const SOUL_TEXTURE := preload("res://assets/ui/point.png")

## Ícones 7×7 desenhados como texto. "o" é sempre o contorno escuro.
const ICONS := {
	"heart": [[
		".oo.oo.",
		"oRRoRRo",
		"oRWRRRo",
		"oRRRRRo",
		".oRRRo.",
		"..oRo..",
		"...o...",
	], {"R": "e83b3b", "W": "f68181"}],
	"shield": [[
		"ooooooo",
		"oBBBBBo",
		"oBWBBBo",
		"oBBBBBo",
		".oBBBo.",
		"..oBo..",
		"...o...",
	], {"B": "4d9be6", "W": "8fd3ff"}],
	"damage": [[
		"....ooo",
		"...oWWo",
		"..oWWo.",
		"ooWWo..",
		"oSoo...",
		"oSSo...",
		"ooo....",
	], {"W": "ffffff", "S": "9babb2"}],
	"crit": [[
		"...o...",
		"..oYo..",
		"ooYWYoo",
		"oYYYYYo",
		".oYYYo.",
		".oYoYo.",
		".oo.oo.",
	], {"Y": "f9c22b", "W": "fbff86"}],
	"rate": [[
		"...ooo.",
		"..oYYo.",
		".oYYo..",
		"oYYYYo.",
		".oYYo..",
		".oYo...",
		".oo....",
	], {"Y": "fbb954"}],
	"speed": [[
		"oo.oo..",
		"oWooWo.",
		".oWooWo",
		"..oWooW",
		".oWooWo",
		"oWooWo.",
		"oo.oo..",
	], {"W": "c7dcd0"}],
	"jump": [[
		"...o...",
		"..oWo..",
		".oWWWo.",
		"ooWWWoo",
		"..oWo..",
		"..oWo..",
		"..ooo..",
	], {"W": "8ff8e2"}],
	"lamp": [[
		"ooooooo",
		"oDDDDDo",
		".oLLLo.",
		"..oDo..",
		"..oDo..",
		"..oDo..",
		".ooooo.",
	], {"D": "625565", "L": "fbff86"}],
	"crown": [[
		".......",
		"o..o..o",
		"oYoYoYo",
		"oYYYYYo",
		"oYRYRYo",
		"oYYYYYo",
		"ooooooo",
	], {"Y": "f9c22b", "R": "e83b3b"}],
	"shop": [[
		"...o...",
		"..oRo..",
		".oRRRo.",
		"oRRRRRo",
		".oTTTo.",
		".oToTo.",
		".ooooo.",
	], {"R": "cd683d", "T": "e6904e"}],
	"lock": [[
		"..ooo..",
		".o...o.",
		"ooooooo",
		"oGGGGGo",
		"oGGoGGo",
		"oGGGGGo",
		"ooooooo",
	], {"G": "9babb2"}],
	"skull": [[
		".ooooo.",
		"oWWWWWo",
		"oWoWoWo",
		"oWWWWWo",
		".oWoWo.",
		".ooooo.",
		".......",
	], {"W": "c7dcd0"}],
}

static var _cache := {}


# --- Texto -----------------------------------------------------------------------

## Rótulo no tamanho da grade da fonte. `outline` para texto direto sobre o jogo.
static func label(text: String, size := FONT_SMALL, color := TEXT, align := HORIZONTAL_ALIGNMENT_CENTER, outline := false) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = align
	node.add_theme_font_size_override(&"font_size", size)
	node.add_theme_color_override(&"font_color", color)
	node.add_theme_constant_override(&"line_spacing", -2)
	if outline:
		node.add_theme_color_override(&"font_outline_color", INK)
		node.add_theme_constant_override(&"outline_size", 4 if size >= FONT_LARGE else 3)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Aplica o contorno escuro a um rótulo já existente (texto sobre o jogo).
static func outline_label(node: Label, size := FONT_SMALL) -> void:
	node.add_theme_color_override(&"font_outline_color", INK)
	node.add_theme_constant_override(&"outline_size", 4 if size >= FONT_LARGE else 3)


# --- Molduras (9-slice) ------------------------------------------------------------

## Painel principal: superfície com brilho em cima e sombra embaixo.
static func panel_box(border := Color.TRANSPARENT, margin := 10) -> StyleBoxTexture:
	var key := "panel_%s_%d" % [border.to_html(), margin]
	if not _cache.has(key):
		var outline := INK if border.a == 0.0 else border
		var box := _frame(outline, SURFACE, SURFACE_HI, PLUM, 1, Color.TRANSPARENT, true)
		box.set_content_margin_all(margin)
		_cache[key] = box
	return _cache[key]


## Poço afundado (lista, slot, entrada da loja permanente). `ring` destaca (hover/foco).
static func inset_box(ring := Color.TRANSPARENT, margin := 4) -> StyleBoxTexture:
	var key := "inset_%s_%d" % [ring.to_html(), margin]
	if not _cache.has(key):
		var box := _frame(PLUM, INK, Color.TRANSPARENT, SURFACE_HI, 1, ring)
		box.set_content_margin_all(margin)
		_cache[key] = box
	return _cache[key]


## Etiqueta pequena (preço, contador, selo).
static func tag_box(fill := INK, margin := 3) -> StyleBoxTexture:
	var key := "tag_%s_%d" % [fill.to_html(), margin]
	if not _cache.has(key):
		var box := _frame(INK, fill, fill.lightened(0.15), fill.darkened(0.3), 1, Color.TRANSPARENT)
		box.set_content_margin_all(margin)
		box.content_margin_top = margin - 1
		_cache[key] = box
	return _cache[key]


static func _frame(outline: Color, fill: Color, hi: Color, shade: Color, shade_rows: int, ring: Color, shadow := false) -> StyleBoxTexture:
	var r := 1 if ring.a > 0.0 else 0
	var drop := 2 if shadow else 0
	var w := 8 + r * 2
	var h := 8 + shade_rows + r * 2 + drop
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var x0 := r
	var y0 := r
	var x1 := w - 1 - r
	var y1 := h - 1 - r - drop
	var ring_bottom := h - 1 - drop
	for y in h:
		for x in w:
			var color := Color.TRANSPARENT
			var inside := x >= x0 and x <= x1 and y >= y0 and y <= y1
			var corner := (x == x0 or x == x1) and (y == y0 or y == y1)
			if inside and corner:
				# Canto cortado; com anel, o canto vira anel para não abrir um buraco.
				color = ring if r > 0 else Color.TRANSPARENT
			elif inside:
				if x == x0 or x == x1 or y == y0 or y == y1:
					color = outline
				elif y == y0 + 1 and hi.a > 0.0:
					color = hi
				elif y > y1 - 1 - shade_rows:
					color = shade
				else:
					color = fill
			elif r > 0 and y <= ring_bottom:
				var ring_corner := (x == 0 or x == w - 1) and (y == 0 or y == ring_bottom)
				if not ring_corner:
					color = ring
			if shadow and color.a == 0.0 and y > y1 and y <= y1 + drop and x > x0 and x <= x1:
				color = Color(INK, 0.6)
			image.set_pixel(x, y, color)
	var box := StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(image)
	box.texture_margin_left = 3 + r
	box.texture_margin_right = 3 + r
	box.texture_margin_top = 3 + r
	box.texture_margin_bottom = 3 + shade_rows + r + drop
	box.expand_margin_left = r
	box.expand_margin_right = r
	box.expand_margin_top = r
	box.expand_margin_bottom = r + drop
	return box


# --- Botões ------------------------------------------------------------------------

## Estilos de botão: [normal, hover, pressed, disabled] para a variante.
static func button_boxes(variant: Variant) -> Array:
	var key := "button_%d" % variant
	if _cache.has(key):
		return _cache[key]
	var spec: Array
	match variant:
		Variant.PRIMARY:
			spec = [GOLD, GOLD_HI, GOLD_LO, TEXT]
		Variant.DANGER:
			spec = [DANGER_LO, DANGER, DANGER_DARK, ACCENT]
		_:
			spec = [SURFACE_HI, LINE, SURFACE, ACCENT]
	var fill: Color = spec[0]
	var hi: Color = spec[1]
	var shade: Color = spec[2]
	var ring: Color = spec[3]
	var normal := _frame(INK, fill, hi, shade, 2, Color.TRANSPARENT)
	var hover := _frame(INK, fill.lightened(0.12), hi.lightened(0.12), shade, 2, ring)
	var pressed := _frame(INK, shade, fill, shade, 0, ring)
	var disabled := _frame(INK, SURFACE, SURFACE, PLUM, 2, Color.TRANSPARENT)
	for box: StyleBoxTexture in [normal, hover, disabled]:
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 3
		box.content_margin_bottom = 5
	# Apertado: sem o "degrau" de baixo, e o texto desce 2 px.
	pressed.content_margin_left = 8
	pressed.content_margin_right = 8
	pressed.content_margin_top = 5
	pressed.content_margin_bottom = 3
	pressed.expand_margin_top -= 2
	pressed.texture_margin_top = 3 + 1
	_cache[key] = [normal, hover, pressed, disabled]
	return _cache[key]


## Pinta um Button qualquer no estilo da variante.
static func style_button(node: Button, variant := Variant.SECONDARY) -> void:
	var boxes := button_boxes(variant)
	node.add_theme_stylebox_override(&"normal", boxes[0])
	node.add_theme_stylebox_override(&"hover", boxes[1])
	node.add_theme_stylebox_override(&"focus", boxes[1])
	node.add_theme_stylebox_override(&"pressed", boxes[2])
	node.add_theme_stylebox_override(&"hover_pressed", boxes[2])
	node.add_theme_stylebox_override(&"disabled", boxes[3])
	var text := INK if variant == Variant.PRIMARY else TEXT
	for state in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color", &"font_hover_pressed_color"]:
		node.add_theme_color_override(state, text)
	node.add_theme_color_override(&"font_disabled_color", LINE)
	node.add_theme_font_size_override(&"font_size", FONT_SMALL)
	if variant == Variant.PRIMARY:
		node.add_theme_constant_override(&"outline_size", 0)
	else:
		node.add_theme_color_override(&"font_outline_color", INK)
		node.add_theme_constant_override(&"outline_size", 3)


static func button(text: String, variant := Variant.SECONDARY, min_size := Vector2(120, 20)) -> PixelButton:
	var node := PixelButton.new()
	node.variant = variant
	node.text = text
	node.custom_minimum_size = min_size
	return node


# --- Ícones, teclas e barras ----------------------------------------------------------

## Ícone 7×7 da lista ICONS (cacheado).
static func icon(name: String) -> ImageTexture:
	var key := "icon_" + name
	if not _cache.has(key):
		var rows: Array = ICONS[name][0]
		var legend: Dictionary = ICONS[name][1]
		var image := Image.create(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
		for y in rows.size():
			for x in rows[y].length():
				var ch: String = rows[y][x]
				if ch == "o":
					image.set_pixel(x, y, INK)
				elif legend.has(ch):
					image.set_pixel(x, y, Color(legend[ch]))
		_cache[key] = ImageTexture.create_from_image(image)
	return _cache[key]


static func icon_rect(name: String) -> TextureRect:
	var node := TextureRect.new()
	node.texture = icon(name)
	node.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	node.custom_minimum_size = Vector2(9, 11)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Ícone de alma (a mesma arte do drop), centralizado numa linha de texto.
static func soul_icon() -> TextureRect:
	var node := TextureRect.new()
	node.texture = SOUL_TEXTURE
	node.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	node.custom_minimum_size = Vector2(10, 11)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Tecla desenhada (atalho): fundo claro com degrau embaixo e texto escuro.
static func key_cap(text: String) -> PanelContainer:
	if not _cache.has("keycap"):
		var box := _frame(INK, MUTED, TEXT, STEEL, 1, Color.TRANSPARENT)
		box.content_margin_left = 3
		box.content_margin_right = 3
		box.content_margin_top = 1
		box.content_margin_bottom = 2
		_cache["keycap"] = box
	var cap := PanelContainer.new()
	cap.add_theme_stylebox_override(&"panel", _cache["keycap"])
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var text_label := label(text, FONT_SMALL, INK)
	text_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	cap.add_child(text_label)
	return cap


## Linha de dica: teclas e textos alternados, ex. hint_row(["1-4", "COMPRAR", "R", "TROCAR"]).
static func hint_row(parts: Array, color := MUTED) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in parts.size():
		if i % 2 == 0:
			row.add_child(key_cap(parts[i]))
		else:
			var text_label := label(parts[i], FONT_SMALL, color, HORIZONTAL_ALIGNMENT_LEFT, true)
			row.add_child(text_label)
			if i < parts.size() - 1:
				var gap := Control.new()
				gap.custom_minimum_size = Vector2(6, 0)
				row.add_child(gap)
	return row


## Barra em pixel art: contorno, trilho, preenchimento com brilho e "fantasma" do dano.
static func draw_bar(canvas: CanvasItem, rect: Rect2, ratio: float, fill: Color, ghost := -1.0, ghost_color := TEXT) -> void:
	rect = Rect2(rect.position.round(), rect.size.round())
	canvas.draw_rect(rect.grow(1), INK)
	canvas.draw_rect(rect, PLUM)
	if ghost > ratio:
		canvas.draw_rect(Rect2(rect.position, Vector2(roundf(rect.size.x * clampf(ghost, 0.0, 1.0)), rect.size.y)), ghost_color)
	var width := roundf(rect.size.x * clampf(ratio, 0.0, 1.0))
	if width <= 0.0:
		return
	canvas.draw_rect(Rect2(rect.position, Vector2(width, rect.size.y)), fill)
	canvas.draw_rect(Rect2(rect.position, Vector2(width, 1)), fill.lightened(0.35))
	if rect.size.y >= 4:
		canvas.draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 1), Vector2(width, 1)), fill.darkened(0.3))


# --- Painéis prontos ---------------------------------------------------------------

## Fundo escurecido + painel centralizado com título. Retorna a coluna do conteúdo.
static func centered_panel(layer: CanvasLayer, width: float, title := "", border := Color.TRANSPARENT) -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", panel_box(border))
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	panel.add_child(column)
	if title != "":
		column.add_child(header(title))
	return column


## Título de painel: texto grande dourado e um filete embaixo.
static func header(title: String, color := ACCENT) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	box.add_child(label(title, FONT_LARGE, color, HORIZONTAL_ALIGNMENT_CENTER, true))
	box.add_child(separator())
	return box


static func separator() -> ColorRect:
	var line := ColorRect.new()
	line.color = SURFACE_HI
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


## Espaço vertical fixo dentro de uma coluna.
static func spacer(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


## Linha "rótulo ...... valor" com ícone opcional (resumo da run, fim de jogo).
static func stat_row(icon_name: String, text: String, value: String, value_color := TEXT) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Sem ícone, um espaço do mesmo tamanho mantém os textos alinhados.
	if icon_name == "soul":
		row.add_child(soul_icon())
	elif icon_name != "":
		row.add_child(icon_rect(icon_name))
	else:
		var blank := Control.new()
		blank.custom_minimum_size = Vector2(9, 11)
		row.add_child(blank)
	var name_label := label(text, FONT_SMALL, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label := label(value, FONT_SMALL, value_color, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(value_label)
	return row
