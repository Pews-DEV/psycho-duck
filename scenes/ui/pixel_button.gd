class_name PixelButton
extends Button
## Botão em pixel art (UiStyle): degrau embaixo, anel de destaque no hover/foco e
## texto que desce ao apertar. PRIMARY (dourado) é a ação principal de cada tela.
## Sem escala no hover: ampliar 5% deixaria os pixels desiguais.

@export var variant: UiStyle.Variant = UiStyle.Variant.SECONDARY:
	set(value):
		variant = value
		if is_inside_tree():
			UiStyle.style_button(self, variant)


func _ready() -> void:
	UiStyle.style_button(self, variant)
	focus_mode = Control.FOCUS_ALL
	# Passar o mouse também move o foco: só um botão aceso por vez (mouse e teclado).
	mouse_entered.connect(func() -> void:
		if disabled:
			return
		if not has_focus():
			grab_focus()
		Sfx.play(&"ui_hover", -10.0, 0.0))
	pressed.connect(func() -> void: Sfx.play(&"ui_click", -4.0, 0.0))
