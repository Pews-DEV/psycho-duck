class_name Enemy
extends Area2D
## Base dos inimigos: vida, dano, flash, drops, versão elite e multiplicadores da onda.
## Cada tipo estende esta classe e implementa _behave() (e, se quiser, _on_ready()).

signal died(enemy: Enemy)
signal health_changed(hp: float, max_hp: float)

const ENEMY_BULLET_SCENE := preload("res://scenes/projectiles/enemy_bullet.tscn")
const PICKUP_SCENE := preload("res://scenes/pickups/pickup.tscn")
const HEAL_DROP_CHANCE := 0.08
## Cura do orbe, em % da vida máxima do pato.
const HEAL_DROP_PERCENT := 10
## Abertura entre os tiros do leque, em radianos.
const SPREAD_STEP := 0.22
## Metade da largura visível (a câmera segue o pato numa arena que pode ser maior).
const HALF_VIEW := View.HALF_WIDTH
## Altura em que os inimigos entram, logo acima do topo da tela.
const ENTRY_Y := View.TOP - 12.0
const GROUND_Y := 156.0
## Elite ("vermelho", como no Seraph's): mais vida, mais dano, mais almas.
const ELITE_HP := 2.5
const ELITE_DAMAGE := 1.4
const ELITE_SOULS := 3
const ELITE_SCALE := 1.3
const ELITE_TINT := Color(1.7, 0.5, 0.5)
## Inimigos que não explodem no contato só machucam de novo depois deste tempo.
const CONTACT_COOLDOWN := 0.8
const LASER_COLOR := Color("e83b3b")
const MAX_SOUL_PICKUPS := 6

var data: EnemyData
var player: Player
var modifiers := {}
var elite := false
var hp := 0.0
var max_hp := 0.0
var is_dying := false
var velocity := Vector2.ZERO
var time := 0.0
## Mira telegrafada (laser): ponto global ou null. `laser_locked` deixa o laser forte.
var laser_target: Variant = null
var laser_locked := false
## (esquerda, direita) da arena quando o inimigo nasceu.
var arena_bounds := Vector2(-32, 352)

var _knockback := Vector2.ZERO
var _contact_timer := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var shape: CollisionShape2D = $Shape


func setup(enemy_data: EnemyData, target: Player, wave_modifiers: Dictionary, is_elite := false) -> void:
	data = enemy_data
	player = target
	modifiers = wave_modifiers
	elite = is_elite


## Onde nasce: no alto, perto do que está na tela, ou logo fora das bordas da tela.
## Tipos com entrada própria (o Skimmer, por exemplo) sobrescrevem.
func pick_spawn_position(bounds: Vector2, view_x: float) -> Vector2:
	if randf() < 0.7:
		return Vector2(clampf(view_x + randf_range(-200, 200), bounds.x + 16.0, bounds.y - 16.0), ENTRY_Y)
	var side_x := view_x - HALF_VIEW - 12.0 if randf() < 0.5 else view_x + HALF_VIEW + 12.0
	return Vector2(side_x, randf_range(-40, 60))


func _ready() -> void:
	add_to_group(&"enemies")
	arena_bounds = Arena.bounds_in(get_tree())
	max_hp = data.max_hp * mod("hp") * (ELITE_HP if elite else 1.0)
	hp = max_hp
	sprite.texture = data.texture
	sprite.material = Fx.flash_material()
	sprite.self_modulate = data.tint * (ELITE_TINT if elite else Color.WHITE)
	var visual_scale := data.sprite_scale * (ELITE_SCALE if elite else 1.0)
	sprite.scale = Vector2(visual_scale, visual_scale)
	var circle := CircleShape2D.new()
	circle.radius = data.hit_radius * (ELITE_SCALE if elite else 1.0)
	shape.shape = circle
	if data.glow_color.a > 0.0:
		add_child(Fx.make_light(data.glow_color, 30.0 * visual_scale, 0.9))
	time = randf() * TAU
	body_entered.connect(_on_body_entered)
	_on_ready()


## Gancho para os tipos inicializarem seus estados.
func _on_ready() -> void:
	pass


## Gancho do comportamento: mexa em `velocity`, atire, troque de estado.
func _behave(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if is_dying:
		return
	time += delta
	_contact_timer -= delta
	_behave(delta)
	_knockback = _knockback.move_toward(Vector2.ZERO, 300.0 * delta)
	position += (velocity + _knockback) * delta
	if not data.dies_on_contact and _contact_timer <= 0.0:
		for body in get_overlapping_bodies():
			if body is Player:
				_touch(body)
	if laser_target != null:
		queue_redraw()


func _draw() -> void:
	if laser_target == null:
		return
	var end: Vector2 = (laser_target as Vector2) - global_position
	if laser_locked:
		var blink := 0.6 + 0.4 * sin(time * 40.0)
		draw_line(Vector2.ZERO, end, Color(LASER_COLOR, blink), 1.5)
	else:
		draw_line(Vector2.ZERO, end, Color(LASER_COLOR, 0.3), 1.0)


# --- Helpers para os tipos -------------------------------------------------

func mod(key: String, default := 1.0) -> float:
	return modifiers.get(key, default)


## Dano já com a escala da onda e o bônus de elite.
func scaled_damage(base: float) -> float:
	return base * mod("damage") * (ELITE_DAMAGE if elite else 1.0)


func move_speed() -> float:
	return data.speed * mod("speed")


func attack_cooldown() -> float:
	return data.shoot_cooldown * mod("cooldown")


func player_position() -> Vector2:
	if player and is_instance_valid(player):
		return player.global_position
	return Vector2(view_center_x(), 150.0)


## Centro horizontal da tela (a câmera segue o pato).
func view_center_x() -> float:
	var cam := get_tree().get_first_node_in_group(&"shake_camera")
	return cam.view_center_x() if cam else (arena_bounds.x + arena_bounds.y) / 2.0


## Mantém um x dentro da arena, com margem.
func clamp_to_arena(x: float, margin := 16.0) -> float:
	return clampf(x, arena_bounds.x + margin, arena_bounds.y - margin)


func player_alive() -> bool:
	return player != null and is_instance_valid(player) and not player.is_dead


## Gira o sprite com a "barriga" apontada para o pato (RotateTowardsPlayer do original).
func face_player(delta: float) -> void:
	var facing := (player_position() - global_position).angle() - PI / 2.0
	sprite.rotation = lerp_angle(sprite.rotation, facing, 6.0 * delta)


## Dispara `count` tiros em leque centrado em `angle`.
## Som de tiro inimigo, baixo para não cansar (vários atiram ao mesmo tempo).
func play_shot_sound() -> void:
	Sfx.play(&"enemy_shoot", -12.0, 0.1)


func fire(angle: float, count := 1, spread := SPREAD_STEP, speed_multiplier := 1.0, damage_multiplier := 1.0, color := Color(0, 0, 0, 0), radius := 0.0) -> void:
	for i in count:
		var bullet := ENEMY_BULLET_SCENE.instantiate()
		bullet.global_position = global_position
		bullet.direction = Vector2.from_angle(angle + (i - (count - 1) / 2.0) * spread)
		bullet.speed = data.bullet_speed * mod("bullet_speed") * speed_multiplier
		bullet.damage = scaled_damage(data.bullet_damage) * damage_multiplier
		if color.a > 0.0:
			bullet.color = color
		if radius > 0.0:
			bullet.radius = radius
		spawn_node(bullet)


## Adiciona um nó ao lado do inimigo, de forma adiada (seguro dentro de callbacks de colisão).
func spawn_node(node: Node2D) -> void:
	get_parent().add_child.call_deferred(node)


## Espera `seconds` segundos respeitando a pausa. Se o inimigo morrer antes, a espera
## nunca termina e a corrotina é descartada junto com ele (sem erro de instância liberada).
func wait(seconds: float) -> Signal:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = maxf(seconds, 0.01)
	add_child(timer)
	timer.start()
	timer.timeout.connect(timer.queue_free)
	return timer.timeout


# --- Dano e morte ------------------------------------------------------------

func take_damage(amount: float, crit: bool, hit_direction := Vector2.ZERO) -> void:
	if is_dying:
		return
	hp -= amount
	health_changed.emit(maxf(hp, 0.0), max_hp)
	Fx.flash(sprite)
	Fx.damage_number(get_parent(), global_position, amount, crit)
	Sfx.play(&"crit_hit" if crit else &"enemy_hit", -6.0)
	_knockback = hit_direction * (70.0 if crit else 45.0) * (1.0 - data.knockback_resist)
	if hp <= 0.0:
		_die(true)


func _on_body_entered(body: Node2D) -> void:
	if is_dying or not body is Player:
		return
	if data.dies_on_contact:
		body.take_damage(scaled_damage(data.contact_damage))
		# Kamikaze: quem encosta no pato explode e não deixa alma.
		_die(false)
	else:
		_touch(body)


func _touch(body: Player) -> void:
	if _contact_timer > 0.0:
		return
	_contact_timer = CONTACT_COOLDOWN
	body.take_damage(scaled_damage(data.contact_damage))


func _die(drop_loot: bool) -> void:
	is_dying = true
	laser_target = null
	Fx.burst(get_parent(), global_position, data.death_color, 16 if not elite else 28, 70.0)
	if data.max_hp >= 500.0:
		Sfx.play(&"boss_death")
	else:
		Sfx.play(&"elite_death" if elite else &"enemy_death", -3.0)
	Fx.shake(get_tree(), 1.5 if not elite else 3.0)
	if drop_loot:
		_drop_souls(data.soul_value * (ELITE_SOULS if elite else 1))
		if elite or randf() < HEAL_DROP_CHANCE:
			_drop(Pickup.Kind.HEAL, HEAL_DROP_PERCENT)
	died.emit(self)
	queue_free()


## Espalha as almas em alguns orbes (no máximo MAX_SOUL_PICKUPS).
func _drop_souls(total: int) -> void:
	if total <= 0:
		return
	var pieces := mini(total, MAX_SOUL_PICKUPS)
	for i in pieces:
		var value := floori(float(total) / pieces) + (1 if i < total % pieces else 0)
		_drop(Pickup.Kind.SOUL, value)


func _drop(kind: Pickup.Kind, value: int) -> void:
	var pickup := PICKUP_SCENE.instantiate()
	pickup.kind = kind
	pickup.value = value
	pickup.position = position
	spawn_node(pickup)
