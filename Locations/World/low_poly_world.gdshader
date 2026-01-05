shader_type spatial;
render_mode cull_back, diffuse_lambert;

uniform sampler2D grass_tex: filter_nearest;
uniform sampler2D sand_tex: filter_nearest;

void fragment() {
	float biome = COLOR.r;

	vec3 sand  = texture(sand_tex, UV).rgb;
	vec3 grass = texture(grass_tex, UV).rgb;

	ALBEDO = mix(grass, sand, step(0.5, biome));
}
