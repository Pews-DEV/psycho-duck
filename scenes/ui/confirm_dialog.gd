class_name ConfirmDialog
extends CanvasLayer
## Pergunta de confirmação (ex.: começar nova run, apagar progresso).
## Uso: var dialog := ConfirmDialog.ask(self, "TÍTULO", "mensagem", "CONFIRMAR", true)
##      dialog.confirmed.connect(...)
## `destructive` pinta o botão de confirmar de vermelho (algo será perdido).

signal confirmed
signal cancelled

var _confirm: PixelButton
var _cancel: PixelButton


static func ask(parent: Node, title: String, message: String, confirm_text: String, destructive := false) -> ConfirmDialog:
	var dialog := ConfirmDialog.new()
	dialog._build(title, message, confirm_text, destructive)
	parent.add_child(dialog)
	return dialog


func _build(title: String, message: String, confirm_text: String, destructive: bool) -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var column := UiStyle.centered_panel(self, 260, title, UiStyle.DANGER_LO if destructive else Color.TRANSPARENT)
	column.add_theme_constant_override(&"separation", 8)
	var text := UiStyle.label(message, UiStyle.FONT_SMALL, UiStyle.MUTED)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size = Vector2(236, 0)
	column.add_child(text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 8)
	column.add_child(row)
	_cancel = UiStyle.button("CANCEL", UiStyle.Variant.SECONDARY, Vector2(110, 20))
	_confirm = UiStyle.button(confirm_text, UiStyle.Variant.DANGER if destructive else UiStyle.Variant.PRIMARY, Vector2(110, 20))
	row.add_child(_cancel)
	row.add_child(_confirm)
	_cancel.pressed.connect(_close.bind(false))
	_confirm.pressed.connect(_close.bind(true))


func _ready() -> void:
	_cancel.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_close(false)


func _close(accepted: bool) -> void:
	if accepted:
		confirmed.emit()
	else:
		cancelled.emit()
	queue_free()
