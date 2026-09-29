extends Node2D
## Raios de luz girando atrás da casinha, como no menu da 0.2.0.

const RAY_COUNT := 14
const LENGTH := 420.0
const COLORS := [Color(0.62, 0.48, 0.2, 0.75), Color(0.5, 0.48, 0.56, 0.6)]

@export var speed := 0.08

var _angle := 0.0


func _process(delta: float) -> void:
	_angle += speed * delta
	queue_redraw()


func _draw() -> void:
	for i in RAY_COUNT:
		var center := _angle + TAU * i / RAY_COUNT
		var width := 0.05 if i % 2 == 0 else 0.035
		var points := PackedVector2Array([
			Vector2.ZERO,
			Vector2.from_angle(center - width) * LENGTH,
			Vector2.from_angle(center + width) * LENGTH,
		])
		draw_colored_polygon(points, COLORS[i % 2])
