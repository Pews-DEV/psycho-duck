extends CanvasLayer
## Vida no canto superior esquerdo; onda e almas no canto superior direito.

var _hp := 25.0
var _max_hp := 25.0

@onready var hp_label: Label = $HpLabel
@onready var bar: Control = $Bar
@onready var wave_label: Label = $WaveLabel
@onready var souls_label: Label = $SoulsLabel
@onready var banner: Label = $Banner
@onready var boss_name: Label = $BossName
@onready var boss_bar: Control = $BossBar

var _boss_ratio := 1.0

## Setas na borda da tela para inimigos fora da visão (a arena pode ser mais larga).
const VIEW_SIZE := View.SIZE
const INDICATOR_COLOR := Color("fbf5ef")
const INDICATOR_DANGER := Color("e83b3b")

@onready var indicators: Control = $Indicators


func _ready() -> void:
	bar.draw.connect(_draw_bar)
	boss_bar.draw.connect(_draw_boss_bar)
	indicators.draw.connect(_draw_indicators)
	banner.modulate.a = 0.0
	boss_name.visible = false
	boss_bar.visible = false


func set_health(hp: float, max_hp: float) -> void:
	_hp = hp
	_max_hp = max_hp
	hp_label.text = "%d / %d" % [ceili(hp), roundi(max_hp)]
	bar.queue_redraw()


func set_wave(wave: int) -> void:
	wave_label.text = "%02d" % wave
	_pop(wave_label)


func set_souls(souls: int) -> void:
	souls_label.text = str(souls)
	_pop(souls_label)


func show_banner(text: String) -> void:
	banner.text = text
	var tween := create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.0)
	tween.tween_property(banner, "modulate:a", 0.0, 0.4)


func _process(_delta: float) -> void:
	indicators.queue_redraw()


func _draw_indicators() -> void:
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.is_dying:
			continue
		var at: Vector2 = enemy.get_global_transform_with_canvas().origin
		if at.x >= 0.0 and at.x <= VIEW_SIZE.x:
			continue
		var y := clampf(at.y, 50.0, 220.0)
		var color := INDICATOR_DANGER if enemy.elite or enemy.data.max_hp >= 500.0 else INDICATOR_COLOR
		var blink := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 120.0)
		var points: PackedVector2Array
		if at.x < 0.0:
			points = [Vector2(3, y), Vector2(10, y - 5), Vector2(10, y + 5)]
		else:
			points = [Vector2(VIEW_SIZE.x - 3, y), Vector2(VIEW_SIZE.x - 10, y - 5), Vector2(VIEW_SIZE.x - 10, y + 5)]
		indicators.draw_colored_polygon(points, Color(color, blink))


func show_boss(boss: Enemy) -> void:
	boss_name.text = tr(boss.data.display_name).to_upper()
	_boss_ratio = 1.0
	boss_name.visible = true
	boss_bar.visible = true
	boss_bar.queue_redraw()
	boss.health_changed.connect(func(hp: float, max_hp: float) -> void:
		_boss_ratio = hp / max_hp
		boss_bar.queue_redraw())
	boss.died.connect(func(_boss: Enemy) -> void:
		boss_name.visible = false
		boss_bar.visible = false)


func _draw_boss_bar() -> void:
	var rect := Rect2(Vector2.ZERO, boss_bar.size)
	boss_bar.draw_rect(rect.grow(1), Color("2e222f"))
	boss_bar.draw_rect(rect, Color("5d2b3a"))
	boss_bar.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(_boss_ratio, 0.0, 1.0), rect.size.y)), Color("fbb954"))
	boss_bar.draw_rect(rect.grow(1), Color("c7dcd0"), false, 0.5)


func _draw_bar() -> void:
	var rect := Rect2(Vector2.ZERO, bar.size)
	bar.draw_rect(rect.grow(1), Color("2e222f"))
	bar.draw_rect(rect, Color("5d2b3a"))
	var ratio := clampf(_hp / _max_hp, 0.0, 1.0) if _max_hp > 0.0 else 0.0
	bar.draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), Color("e83b3b"))
	bar.draw_rect(rect.grow(1), Color("c7dcd0"), false, 0.5)


func _pop(label: Label) -> void:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(1.3, 1.3)
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.15)
