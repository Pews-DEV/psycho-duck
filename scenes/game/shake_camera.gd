extends Camera2D
## Câmera que segue o pato na horizontal, presa aos limites da arena, com tremor de tela.

const HALF_VIEW := View.HALF_WIDTH

var target: Node2D
## (esquerda, direita) da arena em px.
var bounds := Vector2(-32, 352)

var _trauma := 0.0
var _x := 160.0


func _ready() -> void:
	add_to_group(&"shake_camera")
	position.y = View.CAMERA_Y
	_x = position.x


func shake(strength: float) -> void:
	_trauma = minf(_trauma + strength, 6.0)


## Centro horizontal do que está na tela.
func view_center_x() -> float:
	return _x


func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		var min_x := bounds.x + HALF_VIEW
		var max_x := bounds.y - HALF_VIEW
		var goal := clampf(target.global_position.x, min_x, max_x) if max_x > min_x else (bounds.x + bounds.y) / 2.0
		_x = lerpf(_x, goal, 1.0 - exp(-6.0 * delta))
	# Posição arredondada: evita tremidinha de subpixel na pixel art.
	position.x = roundf(_x)

	if _trauma <= 0.0:
		offset = Vector2.ZERO
		return
	_trauma = maxf(_trauma - 18.0 * delta, 0.0)
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _trauma
