extends Enemy
## Abelha: paira acima do pato, gira para ele e atira (em leque nas ondas altas).

var _hover_offset := Vector2.ZERO
var _hover_timer := 0.0
var _shoot_timer := 0.0


func _on_ready() -> void:
	_shoot_timer = randf_range(1.2, attack_cooldown() + 0.8)


func _behave(delta: float) -> void:
	var target := player_position()
	_hover_timer -= delta
	if _hover_timer <= 0.0:
		_hover_timer = randf_range(2.5, 4.0)
		_hover_offset = Vector2(randf_range(-110, 110), randf_range(-125, -70))
	var goal := target + _hover_offset + Vector2(0, sin(time * 3.0) * 6.0)
	goal.x = clamp_to_arena(goal.x)
	goal.y = maxf(goal.y, View.TOP + 16.0)
	var desired := (goal - global_position).limit_length(1.0) * move_speed()
	if global_position.distance_to(goal) < 6.0:
		desired *= 0.2
	velocity = velocity.lerp(desired, 2.5 * delta)
	face_player(delta)

	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and global_position.y > View.TOP + 4.0 and player_alive():
		_shoot_timer = attack_cooldown() * randf_range(0.85, 1.15)
		Fx.flash(sprite, 0.2)
		play_shot_sound()
		fire((target - global_position).angle(), 1 + int(mod("extra_shots", 0)))
