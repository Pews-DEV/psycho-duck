class_name PixelButton
extends Button
## Botão no estilo do START original: fundo escuro, borda branca, hover amarelo.

const INK := Color("2e222f")
const BORDER := Color("fbf5ef")
const HOVER := Color("fbb954")


func _ready() -> void:
	pivot_offset = size / 2.0
	add_theme_stylebox_override(&"normal", _box(BORDER))
	add_theme_stylebox_override(&"hover", _box(HOVER))
	add_theme_stylebox_override(&"pressed", _box(HOVER))
	add_theme_stylebox_override(&"focus", _box(HOVER))
	add_theme_color_override(&"font_color", BORDER)
	add_theme_color_override(&"font_hover_color", HOVER)
	add_theme_color_override(&"font_focus_color", HOVER)
	add_theme_color_override(&"font_pressed_color", HOVER)
	mouse_entered.connect(func() -> void:
		_pop(1.06)
		if not disabled:
			Sfx.play(&"ui_hover", -10.0, 0.0))
	pressed.connect(func() -> void: Sfx.play(&"ui_click", -4.0, 0.0))
	mouse_exited.connect(_pop.bind(1.0))
	button_down.connect(_pop.bind(0.94))


func _box(border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(2)
	box.anti_aliasing = false
	return box


func _pop(target: float) -> void:
	create_tween().tween_property(self, "scale", Vector2(target, target), 0.08)
