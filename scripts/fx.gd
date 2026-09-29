class_name Fx
extends RefCounted
## Efeitos visuais reutilizados por player, inimigos e projéteis.

const FLASH_SHADER := preload("res://assets/shaders/flash.gdshader")
const DAMAGE_COLOR := Color("e83b3b")
const CRIT_COLOR := Color("fbb954")

const LIGHT_TEXTURE := preload("res://assets/sprites/light.tres")


## Material de flash próprio para cada sprite (o uniform não pode ser compartilhado).
static func flash_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FLASH_SHADER
	return mat


static func flash(node: CanvasItem, duration := 0.12) -> void:
	var mat := node.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("flash", 1.0)
	var tween := node.create_tween()
	tween.tween_method(func(v: float) -> void: mat.set_shader_parameter("flash", v), 1.0, 0.0, duration)


static func make_light(color: Color, radius: float, energy := 1.0) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = LIGHT_TEXTURE
	light.color = color
	light.energy = energy
	light.texture_scale = radius * 2.0 / 128.0
	return light


static func damage_number(parent: Node, pos: Vector2, amount: float, crit: bool) -> void:
	if not Settings.damage_numbers:
		return
	var label := Label.new()
	label.text = str(roundi(amount)) + ("!" if crit else "")
	var settings := LabelSettings.new()
	settings.font_size = 10 if crit else 8
	settings.font_color = CRIT_COLOR if crit else DAMAGE_COLOR
	settings.outline_size = 3
	settings.outline_color = Color("2e222f")
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(40, 12)
	label.position = pos + Vector2(-20 + randf_range(-4, 4), -16)
	label.z_index = 50
	# A camada de overlay fica fora do CanvasModulate: o número não escurece com a noite.
	var overlay := parent.get_tree().get_first_node_in_group(&"fx_overlay")
	(overlay if overlay else parent).add_child(label)
	var tween := label.create_tween()
	tween.set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 12, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


static func burst(parent: Node, pos: Vector2, color: Color, amount := 14, speed := 60.0) -> void:
	var particles := CPUParticles2D.new()
	particles.position = pos
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.direction = Vector2.UP
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0, 160)
	particles.damping_min = 20.0
	particles.damping_max = 40.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(color, 0.0))
	ramp.add_point(0.2, color)
	particles.color_ramp = ramp
	particles.z_index = 40
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


static func shake(tree: SceneTree, strength: float) -> void:
	if not Settings.screen_shake:
		return
	var cam := tree.get_first_node_in_group(&"shake_camera")
	if cam and cam.has_method("shake"):
		cam.shake(strength)
