class_name UiStyle
extends RefCounted
## Peças de interface compartilhadas pelos painéis (cores, moldura, rótulos).

const INK := Color("2e222f")
const BORDER := Color("fbf5ef")
const ACCENT := Color("fbb954")
const MUTED := Color("c7dcd0")
const DIM := Color(0.1, 0.07, 0.12, 0.8)


static func panel_box(border := BORDER, margin := 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	box.anti_aliasing = false
	box.set_content_margin_all(margin)
	return box


static func label(text: String, size: int, color := BORDER, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = align
	node.add_theme_font_size_override(&"font_size", size)
	node.add_theme_color_override(&"font_color", color)
	node.add_theme_color_override(&"font_outline_color", INK)
	node.add_theme_constant_override(&"outline_size", 3)
	return node


static func button(text: String, size := 10, min_size := Vector2(120, 24)) -> PixelButton:
	var node := PixelButton.new()
	node.text = text
	node.custom_minimum_size = min_size
	node.add_theme_font_size_override(&"font_size", size)
	return node


## Fundo escurecido + painel centralizado. Retorna a coluna onde vai o conteúdo.
static func centered_panel(layer: CanvasLayer, width: float, border := BORDER) -> VBoxContainer:
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
	return column
