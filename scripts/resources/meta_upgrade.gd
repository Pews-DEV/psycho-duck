class_name MetaUpgrade
extends Resource
## Melhoria da loja permanente do menu: comprada com as almas acumuladas entre runs,
## vale desde o início de todas as runs seguintes.

enum Effect { MAX_HP, DAMAGE, CRIT_CHANCE, DEFENSE, SOUL_GAIN, WAVE_HEAL }

@export var id: StringName
@export var display_name := ""
## O "_" recebe o bônus total do próximo nível.
@export var description := ""
@export var icon: Texture2D
@export var effect: Effect = Effect.MAX_HP
@export var max_level := 5
@export var value_per_level := 3.0
@export var base_cost := 20
## Cada nível custa base_cost · cost_growth^nível.
@export var cost_growth := 1.6


func cost_for(level: int) -> int:
	return roundi(base_cost * pow(cost_growth, level))


func describe(level: int) -> String:
	var value := value_per_level * maxi(level, 1)
	var text := str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)
	return TranslationServer.translate(description).replace("_", text)
