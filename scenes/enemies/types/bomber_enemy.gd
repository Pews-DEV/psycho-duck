extends Enemy
## Bomber: patrulha no alto de um lado para o outro e solta orbes de energia que caem
## e deixam uma poça no chão que machuca quem fica em cima (orbes do Seraph).

const ORB_SCENE := preload("res://scenes/projectiles/energy_orb.tscn")
const PATROL_Y := 5.0
## Patrulha até esta distância do centro da tela, para não sumir na arena grande.
const PATROL_RANGE := 200.0

var _direction := 1.0
var _shoot_timer := 0.0


func _on_ready() -> void:
	_direction = 1.0 if randf() < 0.5 else -1.0
	_shoot_timer = randf_range(1.0, attack_cooldown())


func _behave(delta: float) -> void:
	var center := view_center_x()
	if global_position.x < maxf(center - PATROL_RANGE, arena_bounds.x + 30.0):
		_direction = 1.0
	elif global_position.x > minf(center + PATROL_RANGE, arena_bounds.y - 30.0):
		_direction = -1.0
	var desired := Vector2(_direction * move_speed(), (PATROL_Y + sin(time * 2.0) * 6.0 - global_position.y) * 2.0)
	velocity = velocity.lerp(desired, 2.0 * delta)
	sprite.rotation = lerp_angle(sprite.rotation, _direction * 0.2, 5.0 * delta)

	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and global_position.y > View.TOP + 4.0 and player_alive():
		_shoot_timer = attack_cooldown() * randf_range(0.85, 1.15)
		_drop_orb()


func _drop_orb() -> void:
	Fx.flash(sprite, 0.2)
	Sfx.play(&"orb_drop", -6.0)
	var orb := ORB_SCENE.instantiate()
	orb.global_position = global_position + Vector2(0, 6)
	# Mira um pouco à frente do pato: o orbe cai em arco.
	var fall_time := sqrt(2.0 * maxf(GROUND_Y - global_position.y, 10.0) / orb.GRAVITY)
	var target_x := player_position().x + player.velocity.x * 0.3 if player_alive() else player_position().x
	orb.velocity = Vector2((target_x - global_position.x) / fall_time, 0.0)
	orb.damage = scaled_damage(data.bullet_damage)
	orb.puddle_damage = scaled_damage(data.bullet_damage) * 0.5
	spawn_node(orb)
