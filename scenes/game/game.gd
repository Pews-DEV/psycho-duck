extends Node2D
## Partida: liga player, ondas, upgrades, HUD, pausa e game over.
## A run é salva no início de cada onda; CONTINUE no menu volta desse ponto.

const MENU_SCENE := "res://scenes/ui/menu.tscn"
## A loja abre depois de cada onda múltipla deste número.
const SHOP_EVERY := 5
## Centro da porta da casinha, em x.
const HOUSE_DOOR_X := 183.0
## A arena cresce depois de cada onda múltipla deste número (até o teto da Arena).
const EXPAND_EVERY := 10
## Onde o poste de luz é construído: à esquerda da casinha, a uma certa distância.
const POLE_X := Arena.CENTER_X - 110.0
## A demo termina ao vencer esta onda (dá para seguir no modo infinito).
const DEMO_FINAL_WAVE := 20
## Cura ao limpar uma onda, em % da vida máxima.
const WAVE_CLEAR_HEAL := 15.0

var souls_this_run := 0

var pole: LightPole
## Frações de alma do bônus do Ímã de Almas, acumuladas até virar 1.
var _soul_fraction := 0.0

var _pending_wave := 1
var _run_over := false

@onready var arena: Arena = $Arena
@onready var camera: Camera2D = $Camera
@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player
@onready var spawner: WaveSpawner = $Spawner
@onready var hud: CanvasLayer = $Hud
@onready var upgrade_select: CanvasLayer = $UpgradeSelect
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var game_over: CanvasLayer = $GameOver
@onready var shop: CanvasLayer = $Shop
@onready var demo_end: DemoEndPanel = $DemoEnd


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	$Overlay.add_to_group(&"fx_overlay")

	camera.target = player
	camera.bounds = arena.bounds()
	arena.expanded.connect(func(_stage: int) -> void: camera.bounds = arena.bounds())
	spawner.player = player
	spawner.entities = entities
	player.bullets_parent = entities
	player.health_changed.connect(hud.set_health)
	player.soul_collected.connect(_on_soul_collected)
	player.died.connect(_on_player_died)
	spawner.wave_cleared.connect(_on_wave_cleared)
	spawner.boss_spawned.connect(hud.show_boss)
	spawner.boss_spawned.connect(_on_boss_spawned)
	upgrade_select.upgrade_chosen.connect(_on_upgrade_chosen)
	pause_menu.quit_to_menu.connect(_go_to_menu)
	pause_menu.abandon.connect(_abandon_run)
	game_over.retry.connect(_restart)
	game_over.quit_to_menu.connect(_go_to_menu)
	shop.souls_changed.connect(_on_shop_souls_changed)
	shop.purchased.connect(_on_shop_purchase)

	var first_wave := 1
	if GameState.resume_requested:
		GameState.resume_requested = false
		first_wave = _restore_run(GameState.load_run())
	else:
		GameState.clear_run()
	hud.set_health(player.hp, player.stats.max_hp)
	hud.set_souls(souls_this_run)
	_begin_wave(first_wave)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not _run_over and not upgrade_select.visible and not shop.visible:
		get_viewport().set_input_as_handled()
		pause_menu.open({"wave": _pending_wave, "souls": souls_this_run, "hp": player.hp,
			"stats": player.stats, "pole": pole})


## Cada onda começa com a escolha de um upgrade, como na 0.2.0.
func _begin_wave(wave: int) -> void:
	_pending_wave = wave
	var shop_wave := ceili(wave / float(SHOP_EVERY)) * SHOP_EVERY
	hud.set_wave(wave, spawner.is_boss_wave(wave), shop_wave)
	GameState.save_run(_snapshot(wave))
	upgrade_select.open(wave)


func _on_upgrade_chosen(upgrade: UpgradeData, rarity: UpgradeData.Rarity) -> void:
	player.apply_upgrade(upgrade, rarity)
	if spawner.is_boss_wave(_pending_wave):
		hud.show_banner(tr("BOSS WAVE"), UiStyle.DANGER)
	else:
		hud.show_banner(tr("WAVE %d") % _pending_wave)
	Sfx.play(&"wave_start", -4.0, 0.0)
	spawner.start_wave(_pending_wave)


func _on_wave_cleared(wave: int) -> void:
	if _run_over:
		return
	var new_skins := GameState.register_wave_cleared(wave)
	if new_skins.is_empty():
		hud.show_banner(tr("WAVE CLEAR"))
		Sfx.play(&"wave_clear", -3.0, 0.0)
	else:
		hud.show_banner(tr("NEW SKIN: %s!") % tr(new_skins[0].display_name).to_upper())
		Sfx.play(&"skin_unlock", -2.0, 0.0)
	var heal_percent := WAVE_CLEAR_HEAL + GameState.meta_bonus(MetaUpgrade.Effect.WAVE_HEAL)
	player.heal(player.stats.max_hp * heal_percent / 100.0)
	await get_tree().create_timer(1.8, false).timeout
	await _wait_for_pickups()
	if _run_over:
		return
	if wave == DEMO_FINAL_WAVE:
		GameState.mark_demo_completed()
		demo_end.open()
		var keep_going: bool = await demo_end.chosen
		if not keep_going:
			_finish_run_at_menu(wave)
			return
	if wave % EXPAND_EVERY == 0 and arena.can_expand():
		await _expand_arena()
		if _run_over:
			return
	if wave % SHOP_EVERY == 0:
		await _visit_shop(wave)
		if _run_over:
			return
	_begin_wave(wave + 1)


## Dá tempo das almas que ainda estão voando chegarem ao pato (no máximo 3 s).
func _wait_for_pickups() -> void:
	var waited := 0.0
	while waited < 3.0 and entities.get_children().any(func(node: Node) -> bool: return node is Pickup):
		await get_tree().create_timer(0.1, false).timeout
		waited += 0.1


func _expand_arena() -> void:
	hud.show_banner(tr("THE ARENA GROWS!"))
	Fx.shake(get_tree(), 5.0)
	Sfx.play(&"arena_grow", 0.0, 0.0)
	await arena.expand()


## O pato anda até a porta, entra na casinha e a loja abre; ao sair, volta a jogar.
func _visit_shop(wave: int) -> void:
	hud.show_banner(tr("SHOP TIME"))
	player.walk_to(HOUSE_DOOR_X)
	await player.arrived
	Sfx.play(&"door", -2.0, 0.0)
	await player.enter_house().finished
	shop.open(souls_this_run, wave, _shop_flags())
	await shop.closed
	Sfx.play(&"door", -2.0, 0.0)
	await player.exit_house().finished


func _on_shop_souls_changed(souls: int) -> void:
	souls_this_run = souls
	hud.set_souls(souls)


func _on_shop_purchase(upgrade: UpgradeData, rarity: UpgradeData.Rarity) -> void:
	match upgrade.stat:
		UpgradeData.Stat.POLE_BUILD:
			_build_pole()
		UpgradeData.Stat.POLE_DAMAGE, UpgradeData.Stat.POLE_FIRE_RATE, UpgradeData.Stat.POLE_BURST, UpgradeData.Stat.POLE_RANGE:
			if pole:
				pole.apply_upgrade(upgrade, rarity)
		_:
			player.apply_upgrade(upgrade, rarity)
	if upgrade.permanent:
		GameState.dress(player.sprite)
	shop.set_flags(_shop_flags())


## Condições que a loja usa para decidir quais cartas oferecer.
func _shop_flags() -> Dictionary:
	return {"pole_missing": pole == null, "pole_built": pole != null}


func _build_pole() -> void:
	if pole:
		return
	pole = LightPole.new()
	pole.position = Vector2(POLE_X, arena.ground_y)
	add_child(pole)
	# Atrás do pato e dos inimigos.
	move_child(pole, entities.get_index())
	hud.set_pole(pole)


func _on_soul_collected(amount: int) -> void:
	_soul_fraction += amount * (1.0 + GameState.meta_bonus(MetaUpgrade.Effect.SOUL_GAIN) / 100.0)
	var whole := floori(_soul_fraction)
	_soul_fraction -= whole
	souls_this_run += whole
	hud.set_souls(souls_this_run)


func _on_player_died() -> void:
	_run_over = true
	Music.set_boss_mode(false)
	GameState.clear_run()
	await get_tree().create_timer(1.4).timeout
	Sfx.play(&"game_over", 0.0, 0.0)
	var is_record := GameState.register_run(spawner.wave, souls_this_run)
	game_over.open(spawner.wave, souls_this_run, is_record)


func _on_boss_spawned(boss: Enemy) -> void:
	Music.set_boss_mode(true)
	boss.died.connect(func(_boss: Enemy) -> void: Music.set_boss_mode(false))


## Venceu a demo e escolheu voltar ao menu: guarda almas e recorde como fim de run.
func _finish_run_at_menu(wave: int) -> void:
	_run_over = true
	GameState.register_run(wave, souls_this_run)
	GameState.clear_run()
	_go_to_menu()


## Desiste da run: conta como fim de run (almas e recorde) e apaga o checkpoint.
func _abandon_run() -> void:
	_run_over = true
	GameState.register_run(_pending_wave, souls_this_run)
	GameState.clear_run()
	_go_to_menu()


# --- Save da run ---------------------------------------------------------------

## Estado no início da onda: é daqui que a run continua.
func _snapshot(wave: int) -> Dictionary:
	var run := {
		"wave": wave,
		"souls": souls_this_run,
		"hp": player.hp,
		"stats": player.stats.to_dict(),
		"skin": GameState.selected_character,
		"arena_stage": arena.stage,
	}
	if pole:
		run["pole"] = {"damage": pole.damage, "lasers": pole.lasers, "interval": pole.interval,
			"fire_rate_bonus": pole.fire_rate_bonus, "reach": pole.reach}
	return run


## Recria a run salva e retorna a onda em que ela continua.
func _restore_run(run: Dictionary) -> int:
	if run.is_empty():
		return 1
	# Os stats salvos já incluem os itens permanentes: substituem os da criação do pato.
	player.stats.from_dict(run.get("stats", {}))
	player.hp = minf(float(run.get("hp", player.stats.max_hp)), player.stats.max_hp)
	souls_this_run = int(run.get("souls", 0))
	arena.restore_stage(int(run.get("arena_stage", 0)))
	camera.bounds = arena.bounds()
	if run.has("pole"):
		_build_pole()
		for key in run.pole:
			pole.set(key, run.pole[key])
	return int(run.get("wave", 1))


func _restart() -> void:
	Music.set_boss_mode(false)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _go_to_menu() -> void:
	Music.set_boss_mode(false)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU_SCENE)
