class_name LightPole
extends Node2D
## Poste de luz comprado na loja: a cada tantos segundos dispara uma rajada de lasers
## nos inimigos mais próximos dentro do alcance. Começa fraco; a loja vende melhorias.
## Desenho provisório (sem arte): poste, braço e lâmpada.

const POLE_COLOR := Color("3e3546")
const LAMP_COLOR := Color("fbb954")
const BEAM_COLOR := Color("fff4c2")
const HEIGHT := 40.0
const LAMP_OFFSET := Vector2(-4, -HEIGHT - 1)
const BEAM_TIME := 0.12
const LASER_GAP := 0.1

@export var damage := 12.0
@export var lasers := 3
## Segundos entre rajadas, antes do bônus de cadência.
@export var interval := 3.0
@export var fire_rate_bonus := 0.0
@export var reach := 160.0

var _cooldown := 1.0
var _beams: Array = [] # {from, to, age}
var _built := false


func _ready() -> void:
	var light := Fx.make_light(Color("ffe6b0"), 50.0, 0.9)
	light.position = LAMP_OFFSET
	add_child(light)
	# Nasce do chão.
	scale = Vector2(1, 0)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _built = true)
	Fx.burst(get_parent(), position, LAMP_COLOR, 14, 50.0)
	Sfx.play(&"pole_build", -2.0, 0.0)


func burst_interval() -> float:
	return interval / (1.0 + fire_rate_bonus / 100.0)


func apply_upgrade(upgrade: UpgradeData, rarity: UpgradeData.Rarity) -> void:
	var value := upgrade.value_for(rarity)
	match upgrade.stat:
		UpgradeData.Stat.POLE_DAMAGE:
			damage += value
		UpgradeData.Stat.POLE_FIRE_RATE:
			fire_rate_bonus += value
		UpgradeData.Stat.POLE_BURST:
			lasers += int(value)
		UpgradeData.Stat.POLE_RANGE:
			reach += value
	Fx.burst(get_parent(), global_position + LAMP_OFFSET, LAMP_COLOR, 10, 40.0)


func _physics_process(delta: float) -> void:
	for beam in _beams:
		beam.age += delta
	_beams = _beams.filter(func(beam: Dictionary) -> bool: return beam.age < BEAM_TIME)
	queue_redraw()
	if not _built:
		return
	_cooldown -= delta
	if _cooldown <= 0.0 and not _targets().is_empty():
		_cooldown = burst_interval()
		_fire_burst()


## Inimigos no alcance, do mais próximo ao mais distante.
func _targets() -> Array:
	var origin := global_position + LAMP_OFFSET
	var found := get_tree().get_nodes_in_group(&"enemies").filter(func(e: Node) -> bool:
		return not e.is_dying and e.global_position.distance_to(origin) <= reach)
	found.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	return found


func _fire_burst() -> void:
	for i in lasers:
		var targets := _targets()
		if targets.is_empty():
			return
		# Espalha os lasers entre os alvos mais próximos.
		var enemy: Enemy = targets[i % targets.size()]
		_beams.append({"from": LAMP_OFFSET, "to": enemy.global_position - global_position, "age": 0.0})
		enemy.take_damage(damage, false, Vector2.ZERO)
		Sfx.play(&"pole_laser", -8.0, 0.1)
		# Timer filho: se o poste for liberado, a espera some junto (sem corrotina órfã).
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = LASER_GAP
		add_child(timer)
		timer.start()
		await timer.timeout
		timer.queue_free()


func _draw() -> void:
	# Poste
	draw_rect(Rect2(-4, -3, 8, 3), POLE_COLOR)
	draw_rect(Rect2(-1, -HEIGHT, 2, HEIGHT), POLE_COLOR)
	draw_rect(Rect2(-5, -HEIGHT - 1, 5, 2), POLE_COLOR)
	# Lâmpada pisca quando dispara.
	var firing := not _beams.is_empty()
	draw_rect(Rect2(LAMP_OFFSET + Vector2(-2, 1), Vector2(4, 2)), Color.WHITE if firing else LAMP_COLOR)
	for beam in _beams:
		var alpha: float = 1.0 - beam.age / BEAM_TIME
		draw_line(beam.from, beam.to, Color(BEAM_COLOR, alpha), 1.5)
		draw_circle(beam.to, 2.5 * alpha, Color(LAMP_COLOR, alpha))
