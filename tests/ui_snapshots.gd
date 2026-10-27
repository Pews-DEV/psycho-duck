extends Node
## Tira screenshots de todas as telas (menu, painéis, HUD, cartas, loja, pausa, game over).
## Rode a cena (F6) ou: godot --path . res://tests/ui_snapshots.tscn -- --out=C:/pasta
## Sem --out, as imagens vão para user://ui_snapshots/. Não grava save nem run.

var _out := "user://ui_snapshots/"
var _player: Player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.persist = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out))
	_run.call_deferred()


func _process(_delta: float) -> void:
	# Pato imortal enquanto a partida está aberta.
	if _player and is_instance_valid(_player):
		_player.hp = maxf(_player.hp, 1.0)
		_player._invulnerable = 0.0


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _snap(file: String) -> void:
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png(_out + file + ".png")
	print("snap ", file)


func _run() -> void:
	var intro: Node = load("res://scenes/ui/intro.tscn").instantiate()
	intro.set_script(null)
	get_tree().root.add_child(intro)
	await _wait(0.3)
	await _snap("00_intro")
	intro.queue_free()

	var menu: Node = load("res://scenes/ui/menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await _wait(0.6)
	await _snap("01_menu")
	menu._change_character(1)
	await _wait(0.5)
	await _snap("02_menu_locked")
	menu._change_character(-1)
	for panel in [&"settings_panel", &"meta_shop", &"controls_panel", &"credits_panel"]:
		menu.get(panel).open()
		await _wait(0.3)
		await _snap("03_menu_" + String(panel))
		menu.get(panel).close()
	var dialog := ConfirmDialog.ask(menu, tr("START A NEW RUN?"), tr("YOUR SAVED RUN (WAVE %02d) WILL BE LOST.") % 7, "NEW RUN")
	await _wait(0.3)
	await _snap("04_menu_confirm")
	dialog.queue_free()
	menu.queue_free()
	await _wait(0.1)

	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	get_tree().root.add_child(game)
	_player = game.player
	await _wait(0.8)
	await _snap("10_upgrade_select")
	game.upgrade_select._on_card_chosen(game.upgrade_select.cards_root.get_child(0))
	_player.aim_override = Vector2(220, 20)
	await _wait(0.5)
	await _snap("11_hud_banner")
	game._build_pole()
	await _wait(3.5)
	_player.take_damage(6.0)
	await _wait(1.0)
	await _snap("11_hud")
	var boss: EnemyData = game.spawner.boss
	var queen: Enemy = boss.scene.instantiate()
	queen.setup(boss, _player, game.spawner.modifiers_for(10))
	queen.position = Vector2(200, -20)
	queen.died.connect(game.spawner._on_enemy_died)
	game.spawner.alive += 1
	game.entities.add_child(queen)
	game.spawner.boss_spawned.emit(queen)
	_player.hp = 8.0
	_player.health_changed.emit(_player.hp, _player.stats.max_hp)
	await _wait(2.0)
	await _snap("12_hud_boss_low_hp")

	game.pause_menu.open({"wave": 12, "souls": 37, "hp": _player.hp, "stats": _player.stats, "pole": game.pole})
	await _wait(0.3)
	await _snap("13_pause")
	game.pause_menu.close()
	game.shop.open(42, 5, {})
	await _wait(0.8)
	await _snap("14_shop")
	game.shop.close()
	game.demo_end.open()
	await _wait(0.3)
	await _snap("15_demo_end")
	game.demo_end._close()
	game.game_over.open(12, 37, true)
	await _wait(0.4)
	await _snap("16_game_over")
	get_tree().quit()
