shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;
uniform float scale = 1.0;
uniform float effect: hint_range(0.0, 1.0, 0.01) = 1.0;

varying vec3 pos;

void vertex() {
	pos = VERTEX;
	// Called for every vertex the material is visible on.
}

void fragment() {

	float a = 1.3 - clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0);

	vec2 distort = mix(vec2(scale), vec2(1.0), a);

	vec2 uv = SCREEN_UV * mix(distort, vec2(1.0), effect); //* vec2((UV.y / 0.7), 1.0);

	vec3 color = texture(SCREEN_TEXTURE, uv).rgb;

	//ALBEDO = vec3(a);
	ALBEDO = color;
}