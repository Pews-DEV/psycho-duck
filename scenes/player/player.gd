class_name Player
extends CharacterBody2D
## O pato: anda, pula, mira no mouse e atira segurando o botão esquerdo.

signal health_changed(hp: float, max_hp: float)
signal soul_collected(amount: int)
signal died
## Chegou ao destino do walk_to().
signal arrived

const BULLET_SCENE := preload("res://scenes/projectiles/bullet.tscn")
const ACCELERATION := 900.0
const INVULNERABLE_TIME := 0.7
const SPRITE_FEET_Y := 7.0
const AUTO_WALK_SPEED := 0.6
## Camada das plataformas finas (7): desligada por um instante para descer delas.
const PLATFORM_LAYER_BIT := 7
const DROP_THROUGH_TIME := 0.25

@export var base_stats: PlayerStats

var stats: PlayerStats
var hp := 0.0
var is_dead := false
var bullets_parent: Node
## Se definido, mira aqui em vez do mouse (usado pelo teste automatizado).
var aim_override: Variant = null
## Falso enquanto o jogo controla o pato (entrando na loja, por exemplo).
var controls_enabled := true

var _jumps_left := 0
var _shoot_cooldown := 0.0
var _invulnerable := 0.0
var _walk_time := 0.0
var _auto_walking := false
var _auto_target_x := 0.0
var _drop_timer := 0.0
var _gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity"))

@onready var sprite: Sprite2D = $Sprite
@onready var gun: Node2D = $Gun
@onready var pistol: Sprite2D = $Gun/Pistol
@onready var muzzle: Marker2D = $Gun/Pistol/Muzzle


func _ready() -> void:
	add_to_group(&"player")
	stats = base_stats.duplicate()
	hp = stats.max_hp
	for item in GameState.get_owned_items():
		apply_upgrade(item, UpgradeData.Rarity.COMMON)
	sprite.texture = GameState.get_character().texture
	GameState.dress(sprite)
	sprite.material = Fx.flash_material()
	add_child(Fx.make_light(Color("ffe6b0"), 40.0, 0.55))
	if bullets_parent == null:
		bullets_parent = get_parent()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_move(delta)
	if controls_enabled:
		_aim()
		_shoot(delta)
	_animate(delta)
	if _invulnerable > 0.0:
		_invulnerable -= delta
		sprite.modulate.a = 0.35 if fmod(_invulnerable, 0.12) < 0.06 else 1.0
	else:
		sprite.modulate.a = 1.0


func _move(delta: float) -> void:
	var direction := 0.0
	if _auto_walking:
		direction = _auto_walk_direction()
	elif controls_enabled:
		direction = Input.get_axis(&"move_left", &"move_right")
	velocity.x = move_toward(velocity.x, direction * stats.move_speed, ACCELERATION * delta)

	if is_on_floor():
		_jumps_left = stats.max_jumps
	else:
		velocity.y += _gravity * delta

	if controls_enabled and Input.is_action_just_pressed(&"jump") and _jumps_left > 0:
		velocity.y = -stats.jump_strength()
		_jumps_left -= 1
		sprite.scale = Vector2(0.75, 1.3)
		Sfx.play(&"jump", -4.0)
	# Para baixo em cima de uma plataforma: atravessa e cai.
	if controls_enabled and Input.is_action_just_pressed(&"move_down") and is_on_floor():
		_drop_timer = DROP_THROUGH_TIME
		set_collision_mask_value(PLATFORM_LAYER_BIT, false)
		Sfx.play(&"jump", -8.0, 0.05, 0.7)
	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			set_collision_mask_value(PLATFORM_LAYER_BIT, true)
	# Soltar o pulo cedo corta a subida: pulo curto ou longo.
	if Input.is_action_just_released(&"jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	var was_on_floor := is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor():
		sprite.scale = Vector2(1.3, 0.75)
		Sfx.play(&"land", -10.0)


func _auto_walk_direction() -> float:
	var distance := _auto_target_x - global_position.x
	if absf(distance) < 1.5:
		global_position.x = _auto_target_x
		velocity.x = 0.0
		_auto_walking = false
		arrived.emit()
		return 0.0
	gun.rotation = 0.0 if distance > 0.0 else PI
	pistol.flip_v = distance < 0.0
	return signf(distance) * AUTO_WALK_SPEED


## Tira o controle do jogador e anda sozinho até `x`; emite `arrived` ao chegar.
func walk_to(x: float) -> void:
	controls_enabled = false
	_auto_target_x = x
	_auto_walking = true


## Some pela porta da casa. Retorna o tween para dar await em `finished`.
func enter_house() -> Tween:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_property(sprite, "scale", Vector2(0.6, 0.6), 0.35)
	return tween


func exit_house() -> Tween:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void: controls_enabled = true)
	return tween


func _aim() -> void:
	var target: Vector2 = aim_override if aim_override != null else get_global_mouse_position()
	gun.rotation = (target - gun.global_position).angle()
	pistol.flip_v = absf(wrapf(gun.rotation, -PI, PI)) > PI / 2.0
	muzzle.position.y = 1.0 if pistol.flip_v else -1.0


func _shoot(delta: float) -> void:
	_shoot_cooldown -= delta
	pistol.position.x = move_toward(pistol.position.x, 8.0, 40.0 * delta)
	if not Input.is_action_pressed(&"shoot") or _shoot_cooldown > 0.0:
		return
	_shoot_cooldown = stats.fire_interval()

	var crit := randf() * 100.0 < stats.crit_chance
	var damage := stats.projectile_damage * (stats.crit_multiplier if crit else 1.0)
	var bullet := BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.direction = Vector2.from_angle(gun.rotation + randf_range(-0.04, 0.04))
	bullet.speed = stats.projectile_speed
	bullet.damage = damage
	bullet.crit = crit
	bullets_parent.add_child(bullet)
	pistol.position.x = 5.0 # coice
	Sfx.play(&"shoot", -9.0, 0.08, 1.25 if crit else 1.0)


func _animate(delta: float) -> void:
	if controls_enabled or _auto_walking:
		sprite.scale = sprite.scale.lerp(Vector2.ONE, 12.0 * delta)
	if is_on_floor() and absf(velocity.x) > 5.0:
		_walk_time += delta
		sprite.position.y = SPRITE_FEET_Y - absf(sin(_walk_time * 16.0)) * 1.5
	else:
		_walk_time = 0.0
		sprite.position.y = move_toward(sprite.position.y, SPRITE_FEET_Y, 20.0 * delta)


func take_damage(amount: float) -> void:
	if is_dead or _invulnerable > 0.0:
		return
	var damage := amount * (1.0 - stats.defense / 100.0)
	hp = maxf(hp - damage, 0.0)
	_invulnerable = INVULNERABLE_TIME
	Fx.flash(sprite)
	Fx.shake(get_tree(), 4.0)
	health_changed.emit(hp, stats.max_hp)
	Sfx.play(&"player_hurt", -2.0)
	if hp <= 0.0:
		_die()


func heal(amount: float) -> void:
	if is_dead:
		return
	hp = minf(hp + amount, stats.max_hp)
	health_changed.emit(hp, stats.max_hp)


func collect_soul(amount: int) -> void:
	soul_collected.emit(amount)


func apply_upgrade(upgrade: UpgradeData, rarity: UpgradeData.Rarity) -> void:
	var value := upgrade.value_for(rarity)
	match upgrade.stat:
		UpgradeData.Stat.MAX_HP:
			stats.max_hp += value
			hp += value
		UpgradeData.Stat.DEFENSE:
			# 100 - (100 - def)·(1 - v): dois Resist de 10% dão 19%, não 20%.
			stats.defense = minf(100.0 - (100.0 - stats.defense) * (1.0 - value / 100.0), stats.max_defense)
		UpgradeData.Stat.HEAL:
			hp = stats.max_hp
		UpgradeData.Stat.JUMP_HEIGHT:
			# Impulse: pulo e velocidade juntos, para ajudar a desviar.
			stats.jump_height_bonus += value
			stats.move_speed *= 1.0 + value / 100.0
		UpgradeData.Stat.CRIT_CHANCE:
			stats.crit_chance = minf(stats.crit_chance + value, stats.max_crit_chance)
		UpgradeData.Stat.ATTACK_SPEED:
			stats.attack_speed_bonus += value
		UpgradeData.Stat.DAMAGE:
			stats.projectile_damage += value
	health_changed.emit(hp, stats.max_hp)


func _die() -> void:
	is_dead = true
	sprite.visible = false
	gun.visible = false
	velocity = Vector2.ZERO
	Fx.burst(get_parent(), global_position, Color("fbb954"), 28, 90.0)
	Fx.shake(get_tree(), 6.0)
	Sfx.play(&"player_death")
	died.emit()
