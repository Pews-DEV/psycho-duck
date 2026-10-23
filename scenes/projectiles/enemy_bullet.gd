extends Area2D
## Tiro dos inimigos: orbe rosa que voa reto até o pato ou o chão.

const LIFETIME := 5.0
const COLOR := Color("f04f78")

var direction := Vector2.DOWN
var speed := 70.0
var damage := 2.0
var color := COLOR
var radius := 2.5

var _age := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if radius != 2.5:
		var circle := CircleShape2D.new()
		circle.radius = radius
		$Shape.shape = circle
	# Sem luz própria: em ondas altas são dezenas de tiros e cada luz custa um passe de desenho.


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_age * 20.0)
	draw_circle(Vector2.ZERO, radius + pulse * 0.5, color)
	draw_circle(Vector2.ZERO, radius * 0.5, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage)
	Fx.burst(get_parent(), global_position, color, 6, 35.0)
	queue_free()
