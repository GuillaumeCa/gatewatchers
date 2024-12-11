shader_type spatial;
render_mode unshaded;

uniform sampler2D noise: source_color, repeat_enable, filter_linear;
uniform vec3 color: source_color;
uniform vec3 accent_color: source_color;
uniform float speed: hint_range(1.0, 4.0, 0.1) = 2.0;
uniform float alpha: hint_range(0.0, 1.0, 0.01) = 1.0;


void fragment() {
	float mask = 0.23 - pow(UV.y, 2);

	float v = texture(noise, UV + vec2(0.1 * TIME, TIME * 0.2 * speed)).r * mask * 8.0;
	float v_p = texture(noise, UV + vec2(1.2, TIME * 0.1 * speed)).r * mask * 8.0;


	ALBEDO = mix(accent_color * v, color * v, v_p);
	ALPHA = v * alpha;
}
