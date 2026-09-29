extends Node
## Vitrine dos inimigos: invoca cada tipo com o pato imortal e tira screenshots.
## Rode a cena (F6); as imagens vão para user://showcase/ (Projeto > Abrir pasta de dados do usuário).

const OUT := "user://showcase/"

var t := 0.0
var step := 0
var game: Node
var shots := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.persist = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = load("res://scenes/game/game.tscn").instantiate()
	get_tree().root.add_child.call_deferred(game)


func _snap(file: String) -> void:
	get_tree().root.get_texture().get_image().save_png(OUT + file + ".png")


func _spawn(id: String, elite := false) -> Enemy:
	var data: EnemyData = load("res://data/enemies/%s.tres" % id)
	var spawner: WaveSpawner = game.spawner
	var enemy: Enemy = data.scene.instantiate()
	enemy.setup(data, game.player, spawner.modifiers_for(12), elite)
	enemy.position = enemy.pick_spawn_position(Arena.bounds_in(get_tree()), 160.0)
	enemy.died.connect(spawner._on_enemy_died)
	spawner.alive += 1
	game.entities.add_child(enemy)
	if data == spawner.boss:
		spawner.boss_spawned.emit(enemy)
	return enemy


func _process(delta: float) -> void:
	t += delta
	if game == null or not game.is_inside_tree():
		return
	var p: Player = game.player
	p.hp = 999.0
	match step:
		0:
			if t > 1.0:
				game.upgrade_select.visible = false
				get_tree().paused = false
				p.stats.max_hp = 999.0
				p.aim_override = Vector2(160, 0)
				game.spawner.wave = 12
				_spawn("skimmer")
				_spawn("sniper")
				_spawn("bomber")
				_spawn("carrier")
				_spawn("bee", true)
				step = 1
		1:
			if t > 1.6:
				_snap("20_skimmer_warning")
				step = 2
		2:
			if t > 2.4:
				_snap("21_skimmer_dash")
				step = 3
		3:
			if t > 4.2:
				_snap("22_sniper_bomber")
				step = 4
		4:
			if t > 7.0:
				_snap("23_puddles_drones")
				step = 5
		5:
			if t > 9.5:
				_snap("24_later")
				for child in game.entities.get_children():
					if child is Enemy:
						child.queue_free()
				game.spawner.alive = 0
				_spawn("hornet_queen")
				step = 6
		6:
			if t > 13.0:
				_snap("25_boss_a")
				step = 7
		7:
			if t > 16.0:
				_snap("26_boss_b")
				step = 8
		8:
			if t > 19.0:
				_snap("27_boss_c")
				get_tree().quit()
