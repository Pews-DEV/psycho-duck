extends Area2D
## Tiro do pato: faísca laranja com rastro.

const LIFETIME := 1.6
const COLOR := Color("fbb954")
const CRIT_COLOR := Color("fff4c2")

var direction := Vector2.RIGHT
var speed := 260.0
var damage := 40.0
var crit := false

var _age := 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _draw() -> void:
	var color := CRIT_COLOR if crit else COLOR
	draw_line(-direction * 5.0, Vector2.ZERO, Color(color, 0.45), 1.0)
	draw_circle(Vector2.ZERO, 1.5, color)


func _on_area_entered(area: Area2D) -> void:
	if area is Enemy and not area.is_dying:
		area.take_damage(damage, crit, direction)
		_explode()


func _on_body_entered(_body: Node2D) -> void:
	_explode()


func _explode() -> void:
	if is_queued_for_deletion():
		return
	Fx.burst(get_parent(), global_position, COLOR, 5, 40.0)
	queue_free()
