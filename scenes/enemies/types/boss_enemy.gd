extends Enemy
## Chefe (Hornet Queen): aparece a cada 10 ondas, como as "ondas amaldiçoadas" do Seraph.
## Alterna quatro ataques sem repetir o anterior; abaixo de 50% de vida fica mais rápida.
##   RING   - anéis de tiros em todas as direções
##   FAN    - leques mirados no pato
##   SUMMON - solta drones
##   RAIL   - laser + tiro rápido + teletransporte, três vezes

enum Attack { RING, FAN, SUMMON, RAIL }

## Pontos onde ela para, relativos ao centro da tela.
const ANCHORS: Array[Vector2] = [Vector2(-120, 20), Vector2(0, 10), Vector2(120, 20)]
const RING_BULLETS := 10
const FAN_BULLETS := 5
const RAIL_SPEED_MULTIPLIER := 3.2
const RAIL_COLOR := Color("b4f0ff")
const SUMMON_COUNT := 3

var _anchor := Vector2(160, 34)

var _last_attack := -1


func pick_spawn_position(_bounds: Vector2, view_x: float) -> Vector2:
	return Vector2(view_x, View.TOP - 40.0)


func _next_anchor() -> Vector2:
	var anchor: Vector2 = ANCHORS.pick_random()
	return Vector2(clamp_to_arena(view_center_x() + anchor.x, 40.0), anchor.y)


func _on_ready() -> void:
	_anchor = _next_anchor()
	Sfx.play(&"boss_appear", 0.0, 0.0)
	_loop()


func _enraged() -> bool:
	return hp < max_hp * 0.5


func _pace() -> float:
	return mod("cooldown") * (0.7 if _enraged() else 1.0)


func _behave(delta: float) -> void:
	var goal := _anchor + Vector2(sin(time * 0.8) * 12.0, sin(time * 1.7) * 4.0)
	velocity = velocity.lerp((goal - global_position).limit_length(1.0) * move_speed(), 2.0 * delta)
	if laser_target != null and not laser_locked:
		laser_target = player_position()
	face_player(delta)


func _loop() -> void:
	await wait(2.0)
	while not is_dying:
		var options := [Attack.RING, Attack.FAN, Attack.SUMMON, Attack.RAIL].filter(func(a: int) -> bool: return a != _last_attack)
		var attack: int = options.pick_random()
		_last_attack = attack
		if player_alive():
			match attack:
				Attack.RING:
					await _ring()
				Attack.FAN:
					await _fan()
				Attack.SUMMON:
					await _summon()
				Attack.RAIL:
					await _rail()
		_anchor = _next_anchor()
		await wait(1.8 * _pace())


func _ring() -> void:
	var volleys := 3 if _enraged() else 2
	for v in volleys:
		Fx.flash(sprite, 0.2)
		Sfx.play(&"boss_attack", -3.0)
		var offset := v * PI / RING_BULLETS
		for i in RING_BULLETS:
			fire(offset + TAU * i / RING_BULLETS, 1, 0.0, 0.9)
		await wait(0.55 * _pace())


func _fan() -> void:
	for v in 3:
		Fx.flash(sprite, 0.15)
		Sfx.play(&"boss_attack", -5.0, 0.1, 1.3)
		fire((player_position() - global_position).angle(), FAN_BULLETS, 0.18, 1.2)
		await wait(0.4 * _pace())


func _summon() -> void:
	var spawner := get_tree().get_first_node_in_group(&"wave_spawner") as WaveSpawner
	if spawner == null or data.minion == null:
		return
	Fx.flash(sprite, 0.3)
	Sfx.play(&"carrier_spawn", -2.0, 0.0, 0.8)
	for i in SUMMON_COUNT:
		spawner.spawn_minion(data.minion, global_position + Vector2(-16.0 + 16.0 * i, 10.0))
	await wait(0.6)


func _rail() -> void:
	for shot in 3:
		laser_target = player_position()
		laser_locked = false
		Sfx.play(&"sniper_charge", -6.0, 0.0, 1.3)
		await wait(0.7 * _pace())
		laser_locked = true
		await wait(0.3)
		var aim: Vector2 = laser_target
		laser_target = null
		fire((aim - global_position).angle(), 1, 0.0, RAIL_SPEED_MULTIPLIER, 1.0, RAIL_COLOR, 2.5)
		Sfx.play(&"sniper_shot", -2.0, 0.0, 0.8)
		_anchor = _next_anchor()
		global_position = _anchor
		velocity = Vector2.ZERO
		Fx.burst(get_parent(), global_position, RAIL_COLOR, 10, 50.0)
		await wait(0.35)
