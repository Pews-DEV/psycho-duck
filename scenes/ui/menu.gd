extends Control
## Menu: escolha do pato com as setas e START para jogar.
## Skins bloqueadas aparecem como silhueta com a onda que as libera; o START fica apagado.

const GAME_SCENE := "res://scenes/game/game.tscn"
## Posição dos pés do pato dentro de World (que está em escala 2).
const DUCK_FEET_Y := 71.0
const DUCK_SCALE := 1.5
const TITLE_Y := 32.0
const LEFT_ARROW_X := 168.0
const RIGHT_ARROW_X := 282.0
const LOCKED_TINT := Color(0.08, 0.06, 0.1, 0.9)

var _time := 0.0
## Skin mostrada (pode estar bloqueada); a escolhida de fato fica no GameState.
var _browse := 0

@onready var title: TextureRect = $Title
@onready var duck: Sprite2D = $World/Duck
@onready var name_label: Label = $NameLabel
@onready var left_arrow: TextureButton = $LeftArrow
@onready var right_arrow: TextureButton = $RightArrow
@onready var start_button: TextureButton = $Start
@onready var close_button: TextureButton = $Close
@onready var info_label: Label = $Info
@onready var continue_button: PixelButton = $Continue
@onready var options_button: PixelButton = $Options
@onready var settings_panel: SettingsPanel = $SettingsPanel


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	left_arrow.pressed.connect(_change_character.bind(-1))
	right_arrow.pressed.connect(_change_character.bind(1))
	start_button.pressed.connect(_start)
	start_button.mouse_entered.connect(_pop_start.bind(1.08))
	start_button.mouse_exited.connect(_pop_start.bind(1.0))
	start_button.focus_entered.connect(_pop_start.bind(1.08))
	close_button.pressed.connect(get_tree().quit)
	close_button.visible = not OS.has_feature("web")
	info_label.text = "BEST WAVE %02d   SOULS %d   SKINS %d/%d" % [
		GameState.best_wave, GameState.souls, GameState.unlocked_skin_count(), GameState.SKINS.size()]
	_browse = GameState.selected_character
	options_button.pressed.connect(settings_panel.open)
	var run := GameState.load_run() if GameState.has_saved_run() else {}
	continue_button.visible = not run.is_empty()
	if continue_button.visible:
		continue_button.text = "CONTINUE W%02d" % int(run.get("wave", 1))
		continue_button.pressed.connect(_continue_run.bind(int(run.get("skin", 0))))
	GameState.dress(duck)
	_refresh(false)
	start_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	title.position.y = TITLE_Y + roundf(sin(_time * 2.0) * 3.0)
	var nudge := roundf(absf(sin(_time * 4.0)) * 3.0)
	left_arrow.position.x = LEFT_ARROW_X - nudge
	right_arrow.position.x = RIGHT_ARROW_X + nudge


func _unhandled_input(event: InputEvent) -> void:
	if settings_panel.visible:
		return
	if event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		_change_character(-1)
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		_change_character(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _change_character(step: int) -> void:
	_browse = wrapi(_browse + step, 0, GameState.SKINS.size())
	Sfx.play(&"ui_click", -4.0, 0.0, 1.0 if GameState.is_skin_unlocked(_browse) else 0.7)
	GameState.select_skin(_browse)
	_refresh(true)


func _refresh(animate: bool) -> void:
	var skin: SkinData = GameState.SKINS[_browse]
	var unlocked := GameState.is_skin_unlocked(_browse)
	duck.texture = skin.texture
	duck.modulate = Color.WHITE if unlocked else LOCKED_TINT
	name_label.text = skin.display_name if unlocked else "LOCKED - CLEAR WAVE %d" % skin.unlock_wave
	start_button.disabled = not unlocked
	start_button.modulate = Color.WHITE if unlocked else Color(0.45, 0.42, 0.5)
	if not animate:
		return
	var tween := create_tween()
	duck.scale = Vector2(DUCK_SCALE * 1.3, DUCK_SCALE * 0.7)
	tween.tween_property(duck, "scale", Vector2(DUCK_SCALE, DUCK_SCALE), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var hop := create_tween()
	hop.tween_property(duck, "position:y", DUCK_FEET_Y - 8.0, 0.1).set_ease(Tween.EASE_OUT)
	hop.tween_property(duck, "position:y", DUCK_FEET_Y, 0.15).set_ease(Tween.EASE_IN)


func _pop_start(target: float) -> void:
	create_tween().tween_property(start_button, "scale", Vector2(target, target), 0.08)


## Nova run: descarta a run salva, se houver.
func _start() -> void:
	if not GameState.is_skin_unlocked(_browse):
		Sfx.play(&"deny", -4.0, 0.0)
		return
	GameState.resume_requested = false
	_go_to_game()


func _continue_run(skin: int) -> void:
	GameState.selected_character = skin
	GameState.resume_requested = true
	_go_to_game()


func _go_to_game() -> void:
	Sfx.play(&"card_pick", -2.0, 0.0)
	start_button.disabled = true
	continue_button.disabled = true
	var fade := ColorRect.new()
	fade.color = Color(0.18, 0.133, 0.184, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.25)
	tween.tween_callback(get_tree().change_scene_to_file.bind(GAME_SCENE))
