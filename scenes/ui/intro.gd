extends Control
## Abertura: logo da Briba Studio e vai para o menu. Clique ou tecla pula.

const MENU_SCENE := "res://scenes/ui/menu.tscn"

var _leaving := false

@onready var logo: TextureRect = $Logo


func _ready() -> void:
	logo.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(logo, "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.3)
	tween.tween_callback(_leave)


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween()
	tween.tween_property(logo, "modulate:a", 0.0, 0.35)
	tween.tween_callback(get_tree().change_scene_to_file.bind(MENU_SCENE))
