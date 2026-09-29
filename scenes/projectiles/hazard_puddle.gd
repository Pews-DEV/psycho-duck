extends Area2D
## Poça de energia no chão: machuca o pato enquanto ele estiver em cima.

const COLOR := Color("f06ac8")
const LIFETIME := 4.0
const TICK := 0.5
const WIDTH := 30.0

var damage := 2.0

var _age := 0.0
var _tick_timer := 0.0


func _ready() -> void:
	add_to_group(&"hazard")
	var light := Fx.make_light(COLOR, 20.0, 0.6)
	light.position.y = -3.0
	add_child(light)


func _physics_process(delta: float) -> void:
	_age += delta
	_tick_timer -= delta
	if _age >= LIFETIME:
		queue_free()
		return
	if _tick_timer <= 0.0:
		for body in get_overlapping_bodies():
			if body is Player:
				body.take_damage(damage)
				_tick_timer = TICK
	queue_redraw()


func _draw() -> void:
	# Some nos últimos 0,5 s.
	var alpha := clampf((LIFETIME - _age) / 0.5, 0.0, 1.0)
	draw_rect(Rect2(-WIDTH / 2.0, -2.0, WIDTH, 3.0), Color(COLOR, 0.8 * alpha))
	for i in 4:
		var x := -WIDTH / 2.0 + 4.0 + i * 7.0
		var bubble := fmod(_age * 1.5 + i * 0.37, 1.0)
		draw_circle(Vector2(x, -2.0 - bubble * 5.0), 1.0, Color(COLOR, (1.0 - bubble) * alpha))
