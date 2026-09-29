extends Enemy
## Vaga-lume (e drone): voa em zigue-zague direto no pato e explode no contato.


func _behave(delta: float) -> void:
	var forward := (player_position() - global_position).normalized()
	var side := forward.orthogonal() * sin(time * 4.0) * 0.8
	velocity = velocity.lerp((forward + side).normalized() * move_speed(), 3.0 * delta)
	sprite.rotation = lerp_angle(sprite.rotation, clampf(velocity.x * 0.012, -0.5, 0.5), 8.0 * delta)
	sprite.position.y = sin(time * 10.0) * 0.8
