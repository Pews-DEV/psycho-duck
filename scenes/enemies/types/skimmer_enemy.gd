extends Enemy
## Skimmer: voa rente ao chão atravessando a arena de lado a lado, e volta.
## Um "!" na borda avisa de onde vem; é preciso pular por cima (inspirado nos
## inimigos espinhosos de voo baixo do Seraph's Last Stand).

enum State { WARN, DASH, TURN }

const WARN_TIME := 0.8
const FLY_Y := GROUND_Y - 9.0
const EXIT_MARGIN := 24.0

var _state := State.WARN
var _direction := 1.0
var _timer := WARN_TIME


func pick_spawn_position(bounds: Vector2, _view_x: float) -> Vector2:
	_direction = 1.0 if randf() < 0.5 else -1.0
	return Vector2(bounds.x - EXIT_MARGIN if _direction > 0.0 else bounds.y + EXIT_MARGIN, FLY_Y)


func _on_ready() -> void:
	sprite.flip_h = _direction < 0.0
	Sfx.play(&"skimmer_warn", -6.0, 0.0)


func _behave(delta: float) -> void:
	match _state:
		State.WARN:
			velocity = Vector2.ZERO
			_timer -= delta
			queue_redraw()
			if _timer <= 0.0:
				_state = State.DASH
				queue_redraw()
		State.DASH:
			velocity = Vector2(_direction * move_speed(), 0.0)
			position.y = FLY_Y + sin(time * 12.0) * 1.5
			var left_arena := position.x > arena_bounds.y + EXIT_MARGIN if _direction > 0.0 else position.x < arena_bounds.x - EXIT_MARGIN
			if left_arena:
				_state = State.TURN
				_timer = randf_range(0.6, 1.4) * mod("cooldown")
				_direction = -_direction
				sprite.flip_h = _direction < 0.0
		State.TURN:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_state = State.WARN
				_timer = WARN_TIME
				Sfx.play(&"skimmer_warn", -6.0, 0.0)


func _draw() -> void:
	if _state != State.WARN or fmod(time, 0.2) > 0.12:
		return
	# Aviso na borda por onde ele vai entrar, trazido para dentro da tela se a arena for maior.
	var center := view_center_x()
	var arena_edge := arena_bounds.x + 6.0 if _direction > 0.0 else arena_bounds.y - 6.0
	var edge_x := clampf(arena_edge, center - HALF_VIEW + 6.0, center + HALF_VIEW - 6.0)
	var at := Vector2(edge_x - position.x, 0.0)
	draw_rect(Rect2(at + Vector2(-1, -7), Vector2(2, 6)), LASER_COLOR)
	draw_rect(Rect2(at + Vector2(-1, 1), Vector2(2, 2)), LASER_COLOR)
