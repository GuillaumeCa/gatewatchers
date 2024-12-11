shader_type spatial;
render_mode unshaded, cull_front;

uniform sampler2D noise;
uniform sampler2D gradient;
uniform vec4 color: source_color;
uniform float alpha: hint_range(0.0, 1.0, 0.01);


void fragment() {
	float uv = min(UV.y + 0.003, 0.99);
	float grad = texture(gradient, vec2(uv)).r;
	float grad_m = texture(gradient, vec2(UV.y + TIME * 0.4), 0.0).r * 1.0;
	float n = texture(noise, UV - vec2(TIME * 0.2, TIME * 0.3)).r * 3.0;
	float n_p = texture(noise, UV - vec2(TIME * 0.4, TIME * 0.1)).r;

	ALBEDO = mix(color.rgb * n * n_p * grad_m, color.rgb + abs(sin(TIME * 2.0)) * 0.1, grad);
	ALPHA = mix(n, 1.0, grad) * grad * alpha;
}