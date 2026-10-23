extends Node
## Bot de balanceamento: joga runs completas em headless e imprime uma linha JSON por onda.
## --fixed-fps faz o tempo do jogo correr o mais rápido que a CPU deixar.
## Uso:
##   godot --headless --fixed-fps 60 --audio-driver Dummy --path . res://tests/balance_bot.tscn -- runs=6 dodge=1 seed=7 > runs.jsonl
##   python tests/balance_report.py runs.jsonl
## dodge=1 desvia de tiros e vaga-lumes (jogador bom); dodge=0 fica parado (jogador fraco).

const GAME_SCENE := preload("res://scenes/game/game.tscn")
const MAX_WAVE := 45
const PICK_WEIGHT := {
	&"catalyst": 1.0, &"resonance": 1.0, &"eyesight": 0.8, &"growth": 0.75,
	&"resist": 0.75, &"impulse": 0.35, &"renew": 0.0, &"glasses": 2.0, &"top_hat": 2.0,
}

var runs := 6
var dodge := true
var rng_seed := 1000
var run_index := 0
var game: Node
var wave_start_time := 0.0
var wave_start_hp := 0.0
var damage_this_wave := 0.0
var time := 0.0
var last_hp := 0.0
var finished_run := false
var restart_at := -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=")
		if parts[0] == "runs":
			runs = int(parts[1])
		elif parts[0] == "dodge":
			dodge = parts[1] == "1"
		elif parts[0] == "seed":
			rng_seed = int(parts[1])
	seed(rng_seed)
	GameState.persist = false
	_start_run.call_deferred()


func _start_run() -> void:
	if game:
		game.queue_free()
		await get_tree().process_frame
	GameState.owned_items.clear()
	# Run "do zero": sem as melhorias permanentes do save de quem roda o bot.
	GameState.meta_levels.clear()
	finished_run = false
	game = GAME_SCENE.instantiate()
	get_tree().root.add_child(game)
	game.player.health_changed.connect(_on_health_changed)
	game.spawner.wave_cleared.connect(_on_wave_cleared)
	game.player.died.connect(_on_died)
	last_hp = game.player.hp
	wave_start_hp = last_hp


func _on_health_changed(hp: float, _max_hp: float) -> void:
	if hp < last_hp:
		damage_this_wave += last_hp - hp
	last_hp = hp


func _on_wave_cleared(wave: int) -> void:
	_log_wave(wave, false)


func _on_died() -> void:
	_log_wave(game.spawner.wave, true)
	# Espera o game over abrir (a partida ainda tem um timer pendente).
	restart_at = time + 2.0


func _log_wave(wave: int, died: bool) -> void:
	var p: Player = game.player
	print(JSON.stringify({
		"run": run_index, "wave": wave, "died": died,
		"duration": snappedf(time - wave_start_time, 0.1),
		"damage": snappedf(damage_this_wave, 0.1), "hp": snappedf(p.hp, 0.1), "max_hp": p.stats.max_hp,
		"souls": game.souls_this_run, "dmg": p.stats.projectile_damage,
		"aps": snappedf(p.stats.attack_speed * (1 + p.stats.attack_speed_bonus / 100.0), 0.01),
		"crit": p.stats.crit_chance, "def": snappedf(p.stats.defense, 0.1),
	}))


func _process(delta: float) -> void:
	time += delta
	if game == null or not is_instance_valid(game):
		return
	if restart_at > 0.0 and time >= restart_at:
		restart_at = -1.0
		finished_run = true
	if finished_run:
		finished_run = false
		run_index += 1
		if run_index >= runs:
			get_tree().quit()
		else:
			get_tree().paused = false
			_start_run()
		return

	var select = game.upgrade_select
	if select.visible and select.cards_root.get_child_count() > 0:
		_pick_card(select)
		return
	if game.shop.visible:
		_shop()
		return
	# Fim da demo (onda 20): segue no modo infinito para medir as ondas seguintes.
	if game.demo_end.visible:
		game.demo_end._continue.pressed.emit()
		return
	if game.spawner.wave >= MAX_WAVE and not game.player.is_dead and restart_at < 0.0:
		_log_wave(game.spawner.wave, false)
		game.player.died.disconnect(_on_died)
		game.player.take_damage(99999)
		restart_at = time + 2.0


func _physics_process(_delta: float) -> void:
	if game == null or not is_instance_valid(game) or get_tree().paused:
		_release_moves()
		return
	var p: Player = game.player
	if p.is_dead or not p.controls_enabled:
		_release_moves()
		Input.action_release(&"shoot")
		return
	var target := _nearest_enemy(p)
	if target:
		p.aim_override = target.global_position
		Input.action_press(&"shoot")
	else:
		Input.action_release(&"shoot")
	if dodge:
		_dodge(p)


func _nearest_enemy(p: Player) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for child in game.entities.get_children():
		if child is Enemy and not child.is_dying:
			# Vaga-lumes têm prioridade: são os que chegam no pato.
			var d: float = child.global_position.distance_to(p.global_position) * (0.5 if _is_rammer(child) else 1.0)
			if d < best_d:
				best_d = d
				best = child
	return best


## Desvio simples: prevê tiros e vaga-lumes que vão passar perto e anda para o lado oposto.
func _dodge(p: Player) -> void:
	var push := 0.0
	var jump := false
	for child in game.entities.get_children():
		var pos: Vector2
		var vel: Vector2
		if child.scene_file_path == "res://scenes/projectiles/enemy_bullet.tscn":
			pos = child.global_position
			vel = child.direction * child.speed
		elif child.scene_file_path == "res://scenes/projectiles/energy_orb.tscn":
			pos = child.global_position
			vel = child.velocity
		elif child is Enemy and _is_rammer(child):
			pos = child.global_position
			vel = child.velocity
		elif child.is_in_group(&"hazard"):
			if absf(child.global_position.x - p.global_position.x) < 22.0:
				push += 1.0 if p.global_position.x >= child.global_position.x else -1.0
			continue
		else:
			continue
		for i in 6:
			var t := i * 0.1
			var future: Vector2 = pos + vel * t
			if future.distance_to(p.global_position) < 12.0:
				push += -signf(future.x - p.global_position.x + 0.01) * (1.0 - t)
				if absf(vel.y) < absf(vel.x):
					jump = true
				break
	# Fica longe das bordas da arena para não encurralar.
	var bounds := Arena.bounds_in(get_tree())
	if p.global_position.x < bounds.x + 50.0:
		push += 0.4
	elif p.global_position.x > bounds.y - 50.0:
		push -= 0.4
	_release_moves()
	if push > 0.15:
		Input.action_press(&"move_right")
	elif push < -0.15:
		Input.action_press(&"move_left")
	if jump and p.is_on_floor():
		Input.action_press(&"jump")
	else:
		Input.action_release(&"jump")


## Inimigos que machucam encostando (vaga-lume, drone, skimmer).
func _is_rammer(enemy: Enemy) -> bool:
	return enemy.data.dies_on_contact or enemy.data.id == &"skimmer"


func _release_moves() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")


func _score(upgrade: UpgradeData, rarity: int, p: Player) -> float:
	var missing := 1.0 - p.hp / p.stats.max_hp
	if upgrade.id == &"renew":
		return 3.0 * missing
	var weight: float = PICK_WEIGHT.get(upgrade.id, 0.5)
	if upgrade.id == &"growth" or upgrade.id == &"resist":
		weight += missing
	return weight * (1.0 + 0.6 * rarity)


func _pick_card(select) -> void:
	var p: Player = game.player
	var best = null
	var best_score := -1.0
	for card in select.cards_root.get_children():
		if card.is_queued_for_deletion():
			continue
		var s := _score(card.upgrade, card.rarity, p)
		if s > best_score:
			best_score = s
			best = card
	wave_start_time = time
	damage_this_wave = 0.0
	select._on_card_chosen(best)


func _shop() -> void:
	var shop = game.shop
	var p: Player = game.player
	while true:
		var best := -1
		var best_value := 0.0
		for i in shop._offers.size():
			var offer = shop._offers[i]
			if offer == null or offer.price > shop.souls:
				continue
			var value: float = _score(offer.upgrade, offer.rarity, p) / offer.price
			if value > best_value:
				best_value = value
				best = i
		if best < 0:
			break
		shop._buy(best)
	shop.close()
