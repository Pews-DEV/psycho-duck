class_name WaveSpawner
extends Node
## Ondas infinitas. A dificuldade cresce mais em perigo (dano, cadência, tiros em leque)
## do que em vida, para as ondas ficarem mais tensas em vez de mais longas.

signal wave_cleared(wave: int)
signal boss_spawned(boss: Enemy)

@export var enemy_types: Array[EnemyData] = []

@export_group("Chefe")
@export var boss: EnemyData
## Onda de chefe a cada tantas ondas; nela vêm menos inimigos comuns.
@export var boss_every := 10
@export_range(0.0, 1.0) var boss_wave_escort := 0.35

@export_group("Elites")
## Elites (versão vermelha) começam nesta onda e ficam mais comuns até o teto.
@export var elite_start_wave := 10
@export var elite_chance_per_wave := 0.015
@export var max_elite_chance := 0.15

@export_group("Quantidade")
@export var base_count := 4
@export var count_per_wave := 1.4
@export var max_count := 30
## Inimigos vivos ao mesmo tempo: base + onda / 3, até o teto.
@export var max_alive_base := 5
@export var max_alive_cap := 11

@export_group("Escala por onda")
## Vida: 1 + linear·(n-1) + quadrático·(n-1)².
@export var hp_linear := 0.12
@export var hp_quadratic := 0.006
## Dano: 1 + linear·(n-1) + quadrático·(n-1)². O quadrático mantém a pressão depois da onda 30.
@export var damage_per_wave := 0.04
@export var damage_quadratic := 0.0008
@export var speed_per_wave := 0.012
@export var max_speed_multiplier := 1.4
## Recarga dos tiros multiplicada por este fator a cada onda.
@export var cooldown_decay := 0.98
@export var min_cooldown_multiplier := 0.5
@export var bullet_speed_per_wave := 0.02
@export var max_bullet_speed_multiplier := 1.6
## A cada tantas ondas, atiradores ganham +1 tiro no leque.
@export var extra_shot_every := 20

@export_group("Ritmo")
@export var first_interval := 1.3
@export var interval_decay := 0.95
@export var min_interval := 0.5

var wave := 0
var alive := 0
var player: Player
var entities: Node2D

var _queue: Array[EnemyData] = []
var _spawning := false


func _ready() -> void:
	add_to_group(&"wave_spawner")


func is_boss_wave(number: int) -> bool:
	return boss != null and boss_every > 0 and number % boss_every == 0


func elite_chance_for(number: int) -> float:
	if number < elite_start_wave:
		return 0.0
	return minf((number - elite_start_wave + 1) * elite_chance_per_wave, max_elite_chance)


func start_wave(number: int) -> void:
	wave = number
	_queue = _build_queue(number)
	_spawning = true
	_spawn_loop()


func enemy_count_for(number: int) -> int:
	return mini(base_count + int(count_per_wave * number), max_count)


func max_alive_for(number: int) -> int:
	return mini(max_alive_base + int(number / 3.0), max_alive_cap)


## Multiplicadores aplicados a cada inimigo da onda.
func modifiers_for(number: int) -> Dictionary:
	var n := float(number - 1)
	return {
		"hp": 1.0 + hp_linear * n + hp_quadratic * n * n,
		"damage": 1.0 + damage_per_wave * n + damage_quadratic * n * n,
		"speed": minf(1.0 + speed_per_wave * n, max_speed_multiplier),
		"cooldown": maxf(pow(cooldown_decay, n), min_cooldown_multiplier),
		"bullet_speed": minf(1.0 + bullet_speed_per_wave * n, max_bullet_speed_multiplier),
		"extra_shots": int(number / float(extra_shot_every)),
	}


func _build_queue(number: int) -> Array[EnemyData]:
	var eligible := enemy_types.filter(func(d: EnemyData) -> bool: return d.weight_at(number) > 0.0)
	var weights: Array[float] = []
	var total_weight := 0.0
	for data in eligible:
		var weight: float = data.weight_at(number)
		weights.append(weight)
		total_weight += weight
	var queue: Array[EnemyData] = []
	var count := enemy_count_for(number)
	if is_boss_wave(number):
		count = ceili(count * boss_wave_escort)
	for i in count:
		var roll := randf() * total_weight
		for j in eligible.size():
			roll -= weights[j]
			if roll <= 0.0:
				queue.append(eligible[j])
				break
	# O chefe vai por último na lista: pop_back() o tira primeiro.
	if is_boss_wave(number):
		queue.append(boss)
	return queue


func _spawn_loop() -> void:
	var interval := maxf(min_interval, first_interval * pow(interval_decay, wave - 1))
	var modifiers := modifiers_for(wave)
	var cap := max_alive_for(wave)
	while not _queue.is_empty():
		# Com a tela cheia, espera alguém morrer antes de mandar o próximo.
		while alive >= cap:
			await get_tree().create_timer(0.25, false).timeout
			if not is_inside_tree():
				return
		_spawn(_queue.pop_back(), modifiers)
		# process_always = false: o timer congela quando o jogo pausa.
		await get_tree().create_timer(interval, false).timeout
		if not is_inside_tree():
			return
	_spawning = false
	_check_cleared()


func _spawn(data: EnemyData, modifiers: Dictionary) -> Enemy:
	var is_elite := data.can_be_elite and randf() < elite_chance_for(wave)
	var enemy: Enemy = data.scene.instantiate()
	enemy.setup(data, player, modifiers, is_elite)
	enemy.position = enemy.pick_spawn_position(Arena.bounds_in(get_tree()), _view_x())
	enemy.died.connect(_on_enemy_died)
	alive += 1
	entities.add_child(enemy)
	if data == boss:
		boss_spawned.emit(enemy)
	return enemy


func _view_x() -> float:
	var cam := get_tree().get_first_node_in_group(&"shake_camera")
	return cam.view_center_x() if cam else Arena.CENTER_X


## Inimigos invocados por outros (drones): contam para a onda, nascem onde pedirem.
func spawn_minion(data: EnemyData, at: Vector2) -> Enemy:
	var enemy: Enemy = data.scene.instantiate()
	enemy.setup(data, player, modifiers_for(wave))
	enemy.position = at
	enemy.died.connect(_on_enemy_died)
	alive += 1
	entities.add_child.call_deferred(enemy)
	return enemy


func _on_enemy_died(_enemy: Enemy) -> void:
	alive -= 1
	_check_cleared()


func _check_cleared() -> void:
	if not _spawning and alive <= 0:
		wave_cleared.emit(wave)
