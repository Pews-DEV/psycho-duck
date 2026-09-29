class_name UpgradeData
extends Resource
## Um upgrade da run. O "_" em `description` recebe o valor da raridade sorteada.

enum Stat {
	MAX_HP, DEFENSE, HEAL, JUMP_HEIGHT, CRIT_CHANCE, ATTACK_SPEED, DAMAGE,
	# Poste de luz (categoria "pole" da loja).
	POLE_BUILD, POLE_DAMAGE, POLE_FIRE_RATE, POLE_BURST, POLE_RANGE,
}
enum Rarity { COMMON, RARE, EPIC }

const RARITY_NAMES := ["COMMON", "RARE", "EPIC"]
const RARITY_COLORS := [Color("f2e6d0"), Color("6ec4ff"), Color("d58cff")]
const PERMANENT_NAME := "PERMANENT"
const PERMANENT_COLOR := Color("fbb954")

@export var id: StringName
@export var display_name := ""
@export var icon: Texture2D
@export var description := ""
@export var stat: Stat = Stat.MAX_HP
## Valor por raridade: [comum, raro, épico].
@export var values: Array[float] = [5.0, 8.0, 12.0]
@export var has_rarity := true

@export_group("Loja")
## Só aparece quando o jogo informa esta condição como verdadeira
## (ex.: "pole_missing" para construir o poste, "pole_built" para melhorá-lo).
@export var requires: StringName = &""
## Preço fixo na loja; 0 = usa o preço da raridade.
@export var shop_price := 0

@export_group("Item permanente")
## Comprado na loja, fica salvo e vale para todas as runs.
@export var permanent := false
@export var price := 0
## Sprite vestido no pato (filho do sprite, origem nos pés).
@export var accessory: Texture2D
@export var accessory_offset := Vector2.ZERO


func value_for(rarity: Rarity) -> float:
	return values[rarity]


func describe(rarity: Rarity) -> String:
	if not has_rarity:
		return description
	var v := value_for(rarity)
	var text := str(int(v)) if is_equal_approx(v, roundf(v)) else str(v)
	return description.replace("_", text)


## Pesos [comum, raro, épico]: começa em 72/23/5 e melhora até 50/35/15.
static func rarity_weights(wave: int) -> Array[float]:
	var n := float(wave - 1)
	return [maxf(72.0 - n, 50.0), minf(23.0 + 0.6 * n, 35.0), minf(5.0 + 0.3 * n, 15.0)]


static func roll_rarity(wave := 1) -> Rarity:
	var weights := rarity_weights(wave)
	var roll := randf() * (weights[0] + weights[1] + weights[2])
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0.0:
			return i as Rarity
	return Rarity.COMMON
