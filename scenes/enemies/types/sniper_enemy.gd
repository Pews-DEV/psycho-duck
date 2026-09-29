extends Enemy
## Sniper: sobe para o alto, mira com um laser, trava a mira e dispara um tiro muito
## rápido; logo depois se teletransporta (inspirado no railgun + teleporte do Seraph).

const AIM_TIME := 1.0
const LOCK_TIME := 0.35
const SHOT_SPEED_MULTIPLIER := 3.2
const SHOT_COLOR := Color("b4f0ff")

var _goal := Vector2.ZERO


func _on_ready() -> void:
	_pick_goal()
	_loop()


func _pick_goal() -> void:
	# Sempre perto da tela: o laser precisa ser visível para ser justo.
	_goal = Vector2(clamp_to_arena(view_center_x() + randf_range(-190, 190), 30.0), randf_range(-35, 25))


func _behave(delta: float) -> void:
	velocity = velocity.lerp((_goal - global_position).limit_length(1.0) * move_speed(), 3.0 * delta)
	if global_position.distance_to(_goal) < 4.0:
		velocity *= 0.8
	if laser_target != null and not laser_locked:
		laser_target = player_position()
	face_player(delta)


func _loop() -> void:
	await wait(randf_range(1.2, 2.0))
	while not is_dying:
		if player_alive():
			laser_target = player_position()
			laser_locked = false
			Sfx.play(&"sniper_charge", -8.0, 0.02)
			await wait(AIM_TIME)
			laser_locked = true
			await wait(LOCK_TIME)
			var aim: Vector2 = laser_target
			laser_target = null
			fire((aim - global_position).angle(), 1, 0.0, SHOT_SPEED_MULTIPLIER, 1.0, SHOT_COLOR, 2.0)
			Sfx.play(&"sniper_shot", -4.0)
			await _teleport()
		await wait(attack_cooldown())


func _teleport() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	await tween.finished
	_pick_goal()
	global_position = _goal
	velocity = Vector2.ZERO
	var back := create_tween()
	back.tween_property(sprite, "modulate:a", 1.0, 0.15)
	await back.finished
