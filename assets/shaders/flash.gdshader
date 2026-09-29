shader_type canvas_item;

// Pinta o sprite de uma cor sólida (flash de dano).
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(base.rgb, flash_color.rgb, flash), base.a);
}
