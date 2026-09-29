class_name PlayerStats
extends Resource
## Stats do pato. O player duplica este resource no início de cada run.

@export var max_hp := 30.0
## Redução de dano em %. Cada Resist multiplica o dano recebido (retorno decrescente).
@export var defense := 0.0
@export var max_defense := 60.0
@export var move_speed := 95.0
@export var jump_velocity := 240.0
## Bônus de altura do pulo em %.
@export var jump_height_bonus := 0.0
@export var max_jumps := 1
## Chance de crítico em %.
@export var crit_chance := 5.0
@export var max_crit_chance := 60.0
@export var crit_multiplier := 2.0
## Tiros por segundo.
@export var attack_speed := 3.0
## Bônus de cadência em %.
@export var attack_speed_bonus := 0.0
@export var projectile_damage := 40.0
@export var projectile_speed := 260.0


func fire_interval() -> float:
	return 1.0 / (attack_speed * (1.0 + attack_speed_bonus / 100.0))


func jump_strength() -> float:
	# Altura cresce com v², então +x% de altura pede sqrt na velocidade.
	return jump_velocity * sqrt(1.0 + jump_height_bonus / 100.0)


## Todos os stats num dicionário (para o save da run).
func to_dict() -> Dictionary:
	var data := {}
	for property in get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			data[property.name] = get(property.name)
	return data


func from_dict(data: Dictionary) -> void:
	for key in data:
		if key in self:
			set(key, data[key])
