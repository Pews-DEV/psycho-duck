extends CanvasLayer
## Fim da run: onda alcançada, recorde e almas ganhas.

signal retry
signal quit_to_menu

@onready var stats_label: Label = $Stats
@onready var record_label: Label = $Record
@onready var retry_button: PixelButton = $Retry
@onready var menu_button: PixelButton = $Menu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	retry_button.pressed.connect(func() -> void: retry.emit())
	menu_button.pressed.connect(func() -> void: quit_to_menu.emit())


func open(wave: int, souls: int, is_record: bool) -> void:
	stats_label.text = "WAVE %02d    BEST %02d\nSOULS +%d" % [wave, GameState.best_wave, souls]
	record_label.visible = is_record
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	retry_button.grab_focus()
