extends Enemy
## Carrier (nave-mãe): lento e resistente, flutua no alto e solta drones de tempos em
## tempos (os drones do Seraph). Não explode no contato.

const MAX_MINIONS := 4
const MINIONS_PER_WAVE := 2

var _goal := Vector2.ZERO
## Sem tipo: guarda referências que podem já ter sido liberadas.
var _minions: Array = []
var _spawn_timer := 0.0


func _on_ready() -> void:
	_goal = _next_goal()
	_spawn_timer = attack_cooldown() * 0.5


func _behave(delta: float) -> void:
	if global_position.distance_to(_goal) < 6.0:
		_goal = _next_goal()
	velocity = velocity.lerp((_goal - global_position).limit_length(1.0) * move_speed(), 1.5 * delta)
	sprite.position.y = sin(time * 2.0) * 1.5

	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and global_position.y > View.TOP + 4.0 and player_alive():
		_spawn_timer = attack_cooldown()
		_launch_drones()


func _next_goal() -> Vector2:
	return Vector2(clamp_to_arena(view_center_x() + randf_range(-170, 170), 60.0), randf_range(-15, 30))


func _launch_drones() -> void:
	var active: Array = []
	for minion in _minions:
		if is_instance_valid(minion) and not minion.is_dying:
			active.append(minion)
	_minions = active
	var spawner := get_tree().get_first_node_in_group(&"wave_spawner") as WaveSpawner
	if spawner == null or data.minion == null:
		return
	Fx.flash(sprite, 0.25)
	Sfx.play(&"carrier_spawn", -4.0)
	for i in mini(MINIONS_PER_WAVE, MAX_MINIONS - _minions.size()):
		var offset := Vector2(-8.0 + 16.0 * i, 6.0)
		_minions.append(spawner.spawn_minion(data.minion, global_position + offset))
