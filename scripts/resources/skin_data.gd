class_name SkinData
extends Resource
## Uma skin do pato. Para adicionar uma nova: crie o .tres aqui em data/skins e
## coloque-o na lista SKINS do GameState (a ordem da lista é a ordem no menu).

@export var id: StringName
@export var display_name := ""
@export var texture: Texture2D
## Liberada ao vencer esta onda (0 = liberada desde o começo).
@export var unlock_wave := 0
