shader_type spatial;
render_mode unshaded, blend_mix;

uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 0.0);
	ALPHA = hit_flash;
}
