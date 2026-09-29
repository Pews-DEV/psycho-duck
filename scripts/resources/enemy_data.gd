class_name EnemyData
extends Resource
## Dados de um tipo de inimigo (equivalente ao EnemySO da versão Unity).
## O comportamento vem da cena (`scene`), que estende Enemy.

@export var id: StringName
@export var display_name := ""
@export var scene: PackedScene
@export var max_hp := 80.0
@export var speed := 40.0
@export var contact_damage := 2.0
## Kamikaze: explode ao encostar no pato. Se falso, causa dano no contato e continua.
@export var dies_on_contact := true
@export var hit_radius := 6.0
## 0 = recebe o empurrão normal dos tiros; 1 = não se mexe.
@export_range(0.0, 1.0) var knockback_resist := 0.0
@export_group("Tiro")
@export var bullet_damage := 2.0
@export var bullet_speed := 70.0
## Recarga do ataque principal (tiro, orbe, drones...).
@export var shoot_cooldown := 2.4
@export_group("Spawn")
@export var min_wave := 1
## 0 = não entra na fila normal (drones, chefe).
@export var spawn_weight := 1.0
## Quanto o peso cresce por onda depois de min_wave.
@export var spawn_weight_per_wave := 0.0
@export var max_spawn_weight := 1.0
@export var can_be_elite := true
@export var soul_value := 1
@export_group("Invocação")
## Inimigo que este tipo solta (drones da nave-mãe e do chefe).
@export var minion: EnemyData
@export_group("Visual")
@export var texture: Texture2D
## Placeholder até ter arte própria: cor e escala aplicadas ao sprite.
@export var tint := Color.WHITE
@export var sprite_scale := 1.0
## Alfa > 0 acende uma luz no inimigo.
@export var glow_color := Color(0, 0, 0, 0)
@export var death_color := Color("f2a93b")


func weight_at(wave: int) -> float:
	if spawn_weight <= 0.0 or wave < min_wave:
		return 0.0
	return minf(spawn_weight + spawn_weight_per_wave * (wave - min_wave), maxf(max_spawn_weight, spawn_weight))
