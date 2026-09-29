extends Area2D
## Orbe do Bomber: cai em arco; acerta o pato ou, ao tocar o chão, vira uma poça.

const GRAVITY := 180.0
const COLOR := Color("f06ac8")
const PUDDLE_SCENE := preload("res://scenes/projectiles/hazard_puddle.tscn")

var velocity := Vector2.ZERO
var damage := 3.0
var puddle_damage := 2.0

var _age := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_child(Fx.make_light(COLOR, 16.0, 0.8))


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
	_age += delta
	if _age > 6.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_age * 18.0)
	draw_circle(Vector2.ZERO, 3.5 + pulse, Color(COLOR, 0.5))
	draw_circle(Vector2.ZERO, 2.5, COLOR)
	draw_circle(Vector2.ZERO, 1.0, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return
	if body is Player:
		body.take_damage(damage)
	else:
		# Bateu no chão ou numa caixa: a poça fica na superfície.
		var puddle := PUDDLE_SCENE.instantiate()
		puddle.position = Vector2(position.x, position.y + 2.0)
		puddle.damage = puddle_damage
		get_parent().add_child.call_deferred(puddle)
		Sfx.play(&"puddle", -6.0)
	Fx.burst(get_parent(), global_position, COLOR, 10, 45.0)
	queue_free()
