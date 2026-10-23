extends CanvasLayer
## Esc pausa: continuar, configurações, salvar e sair, ou abandonar a run.

signal resumed
## Sai para o menu mantendo o checkpoint (a run continua do início da onda atual).
signal quit_to_menu
signal abandon

var _confirming_abandon := false

@onready var resume_button: PixelButton = $Resume
@onready var settings_button: PixelButton = $Settings
@onready var save_button: PixelButton = $SaveQuit
@onready var abandon_button: PixelButton = $Abandon
@onready var settings_panel: SettingsPanel = $SettingsPanel
@onready var controls_button: PixelButton = $Controls
@onready var controls_panel: ControlsPanel = $ControlsPanel
@onready var web_hint: Label = $WebHint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(_open_settings)
	save_button.pressed.connect(func() -> void: quit_to_menu.emit())
	abandon_button.pressed.connect(_confirm_abandon)
	settings_panel.allow_reset = false
	settings_panel.closed.connect(func() -> void:
		visible = true
		settings_button.grab_focus())
	controls_button.pressed.connect(func() -> void:
		visible = false
		controls_panel.open("BACK"))
	controls_panel.closed.connect(func() -> void:
		visible = true
		controls_button.grab_focus())
	# No navegador, ESC é usado para sair da tela cheia antes de chegar ao jogo.
	web_hint.visible = OS.has_feature("web")


func open() -> void:
	visible = true
	_confirming_abandon = false
	abandon_button.text = "ABANDON RUN"
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _open_settings() -> void:
	visible = false
	settings_panel.open()


## Abandonar pede um segundo clique, para não perder a run sem querer.
func _confirm_abandon() -> void:
	if _confirming_abandon:
		abandon.emit()
	else:
		_confirming_abandon = true
		abandon_button.text = "SURE?"
