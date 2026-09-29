extends Node2D
## Mira desenhada no cursor durante a partida (o cursor do sistema fica escondido).

const COLOR := Color("fbf5ef")


func _ready() -> void:
	z_index = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position().round()
	visible = Input.mouse_mode == Input.MOUSE_MODE_HIDDEN


func _draw() -> void:
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(dir * 2.0, dir * 5.0, Color("2e222f"), 2.0)
		draw_line(dir * 2.0, dir * 4.5, COLOR, 1.0)
	draw_rect(Rect2(-0.5, -0.5, 1, 1), COLOR)
