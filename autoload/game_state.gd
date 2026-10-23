extends Node
## Estado persistente entre cenas: skin escolhida, almas, recorde, skins e itens liberados,
## melhorias permanentes e marcos da demo.

const SAVE_PATH := "user://save.json"
## Checkpoint da run em andamento (gravado no início de cada onda).
const RUN_PATH := "user://run.json"

## Skins na ordem do menu. Cada uma libera ao vencer a sua unlock_wave (a cada 10 ondas).
const SKINS: Array[SkinData] = [
	preload("res://data/skins/duck.tres"),
	preload("res://data/skins/black_duck.tres"),
	preload("res://data/skins/green_duck.tres"),
]

## Itens que a loja pode oferecer; na ordem em que são desenhados no pato (o último fica por cima).
const PERMANENT_ITEMS: Array[UpgradeData] = [
	preload("res://data/items/glasses.tres"),
	preload("res://data/items/top_hat.tres"),
]

## Loja permanente do menu, na ordem em que aparece.
const META_UPGRADES: Array[MetaUpgrade] = [
	preload("res://data/meta/vitality.tres"),
	preload("res://data/meta/firepower.tres"),
	preload("res://data/meta/sharp_eye.tres"),
	preload("res://data/meta/thick_feathers.tres"),
	preload("res://data/meta/soul_magnet.tres"),
	preload("res://data/meta/second_wind.tres"),
]

var selected_character := 0
var souls := 0
var best_wave := 0
## Maior onda já vencida em qualquer run: libera as skins.
var max_wave_cleared := 0
var owned_items: Array[StringName] = []
## Nível de cada melhoria permanente, por id.
var meta_levels := {}
## A tela de controles aparece só antes da primeira run.
var seen_controls := false
## Venceu a última onda da demo ao menos uma vez.
var demo_completed := false
## Falso nos testes automatizados, para não mexer no save de verdade.
var persist := true
## O menu marca isto ao clicar em CONTINUE; a partida lê e continua do checkpoint.
var resume_requested := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	load_game()


func get_character() -> SkinData:
	return SKINS[selected_character]


func is_skin_unlocked(index: int) -> bool:
	return max_wave_cleared >= SKINS[index].unlock_wave


func select_skin(index: int) -> void:
	if is_skin_unlocked(index):
		selected_character = index
		save_game()


func unlocked_skin_count() -> int:
	return range(SKINS.size()).filter(is_skin_unlocked).size()


## Chamado ao vencer uma onda. Retorna as skins liberadas agora (para o aviso na tela).
func register_wave_cleared(wave: int) -> Array[SkinData]:
	var unlocked: Array[SkinData] = []
	if wave <= max_wave_cleared:
		return unlocked
	var before := max_wave_cleared
	max_wave_cleared = wave
	for skin in SKINS:
		if skin.unlock_wave > before and skin.unlock_wave <= wave:
			unlocked.append(skin)
	save_game()
	return unlocked


func owns(item: UpgradeData) -> bool:
	return item.id in owned_items


func unlock(item: UpgradeData) -> void:
	if not owns(item):
		owned_items.append(item.id)
		save_game()


func get_owned_items() -> Array[UpgradeData]:
	var items: Array[UpgradeData] = []
	items.assign(PERMANENT_ITEMS.filter(owns))
	return items


## Itens que ainda podem aparecer na loja.
func get_locked_items() -> Array[UpgradeData]:
	var items: Array[UpgradeData] = []
	items.assign(PERMANENT_ITEMS.filter(func(item: UpgradeData) -> bool: return not owns(item)))
	return items


## Coloca os acessórios dos itens possuídos como filhos do sprite do pato.
func dress(sprite: Sprite2D) -> void:
	for child in sprite.get_children():
		if child.is_in_group(&"accessory"):
			child.queue_free()
	for item in get_owned_items():
		if item.accessory == null:
			continue
		var accessory := Sprite2D.new()
		accessory.texture = item.accessory
		accessory.centered = false
		accessory.position = item.accessory_offset
		# Herda o material do pato: o flash de dano pinta o acessório junto.
		accessory.use_parent_material = true
		accessory.add_to_group(&"accessory")
		sprite.add_child(accessory)


## Chamado no fim de cada run. Retorna true se bateu o recorde.
func register_run(wave_reached: int, souls_collected: int) -> bool:
	souls += souls_collected
	var is_record := wave_reached > best_wave
	best_wave = maxi(best_wave, wave_reached)
	save_game()
	return is_record


# --- Loja permanente ------------------------------------------------------------

func meta_level(upgrade: MetaUpgrade) -> int:
	return int(meta_levels.get(String(upgrade.id), 0))


## Soma dos bônus comprados de um efeito (ex.: +6 de vida máxima).
func meta_bonus(effect: MetaUpgrade.Effect) -> float:
	var total := 0.0
	for upgrade in META_UPGRADES:
		if upgrade.effect == effect:
			total += upgrade.value_per_level * meta_level(upgrade)
	return total


## Compra o próximo nível; retorna false se não tiver almas ou já estiver no máximo.
func buy_meta(upgrade: MetaUpgrade) -> bool:
	var level := meta_level(upgrade)
	if level >= upgrade.max_level or souls < upgrade.cost_for(level):
		return false
	souls -= upgrade.cost_for(level)
	meta_levels[String(upgrade.id)] = level + 1
	save_game()
	return true


func mark_controls_seen() -> void:
	seen_controls = true
	save_game()


func mark_demo_completed() -> void:
	demo_completed = true
	save_game()


## Apaga todo o progresso: skins, recordes, almas, itens, melhorias e a run salva.
func reset_progress() -> void:
	selected_character = 0
	souls = 0
	best_wave = 0
	max_wave_cleared = 0
	owned_items.clear()
	meta_levels.clear()
	seen_controls = false
	demo_completed = false
	clear_run()
	save_game()


# --- Run salva ---------------------------------------------------------------

func save_run(run: Dictionary) -> void:
	if not persist:
		return
	var file := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(run))


func load_run() -> Dictionary:
	if not FileAccess.file_exists(RUN_PATH):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(RUN_PATH))
	return data if typeof(data) == TYPE_DICTIONARY else {}


func has_saved_run() -> bool:
	return persist and not load_run().is_empty()


func clear_run() -> void:
	if persist and FileAccess.file_exists(RUN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN_PATH))


func save_game() -> void:
	if not persist:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"selected_character": selected_character,
		"souls": souls,
		"best_wave": best_wave,
		"max_wave_cleared": max_wave_cleared,
		"owned_items": owned_items.map(func(id: StringName) -> String: return String(id)),
		"meta_levels": meta_levels,
		"seen_controls": seen_controls,
		"demo_completed": demo_completed,
	}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	max_wave_cleared = int(data.get("max_wave_cleared", 0))
	selected_character = clampi(int(data.get("selected_character", 0)), 0, SKINS.size() - 1)
	if not is_skin_unlocked(selected_character):
		selected_character = 0
	souls = int(data.get("souls", 0))
	best_wave = int(data.get("best_wave", 0))
	owned_items.clear()
	for id in data.get("owned_items", []):
		owned_items.append(StringName(id))
	meta_levels = data.get("meta_levels", {})
	seen_controls = bool(data.get("seen_controls", false))
	demo_completed = bool(data.get("demo_completed", false))


func _register_inputs() -> void:
	_add_keys(&"move_left", [KEY_A, KEY_LEFT])
	_add_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_add_keys(&"jump", [KEY_W, KEY_SPACE, KEY_UP])
	_add_keys(&"move_down", [KEY_S, KEY_DOWN])
	_add_keys(&"pause", [KEY_ESCAPE, KEY_P])
	if not InputMap.has_action(&"shoot"):
		InputMap.add_action(&"shoot")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(&"shoot", click)


func _add_keys(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
