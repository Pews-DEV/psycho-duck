class_name Pickup
extends Area2D
## Drop de inimigo: pula para fora, flutua um instante e voa até o pato.

enum Kind { SOUL, HEAL }

const SOUL_TEXTURE := preload("res://assets/ui/point.png")
const HEAL_COLOR := Color("5ac54f")
const SOUL_COLOR := Color("8fd3ff")
const IDLE_TIME := 0.45

var kind: Kind = Kind.SOUL
var value := 1

var _velocity := Vector2.ZERO
var _age := 0.0
var _player: Player


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_velocity = Vector2(randf_range(-40, 40), randf_range(-70, -40))
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if kind == Kind.SOUL:
		var sprite := Sprite2D.new()
		sprite.texture = SOUL_TEXTURE
		add_child(sprite)
	add_child(Fx.make_light(SOUL_COLOR if kind == Kind.SOUL else HEAL_COLOR, 12.0, 0.7))


func _physics_process(delta: float) -> void:
	_age += delta
	if _age < IDLE_TIME or _player == null or _player.is_dead:
		_velocity = _velocity.move_toward(Vector2.ZERO, 140.0 * delta)
	else:
		var pull := 220.0 + (_age - IDLE_TIME) * 400.0
		var to_player := _player.global_position - global_position
		_velocity = _velocity.move_toward(to_player.normalized() * pull, 900.0 * delta)
	position += _velocity * delta
	queue_redraw()


func _draw() -> void:
	if kind == Kind.HEAL:
		var pulse := 1.0 + 0.2 * sin(_age * 12.0)
		draw_circle(Vector2.ZERO, 3.0 * pulse, HEAL_COLOR)
		draw_rect(Rect2(-0.5, -2, 1, 4), Color.WHITE)
		draw_rect(Rect2(-2, -0.5, 4, 1), Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player or body.is_dead:
		return
	match kind:
		Kind.SOUL:
			body.collect_soul(value)
			Sfx.play(&"soul_pickup", -8.0, 0.1)
		Kind.HEAL:
			body.heal(body.stats.max_hp * value / 100.0)
			Sfx.play(&"heal_pickup", -3.0, 0.0)
	Fx.burst(get_parent(), global_position, SOUL_COLOR if kind == Kind.SOUL else HEAL_COLOR, 6, 30.0)
	queue_free()
