shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D noise: hint_default_black;
uniform float strength = 1.0;
uniform float speed = 1.0;

void fragment() {
	float disp = texture(noise, UV + vec2(0.0, 1.0) * TIME * 0.2 * speed).r * 0.02 * strength;
	ALBEDO.rgb = texture(screen_texture, SCREEN_UV + vec2(pow(UV.y, 3.0) * 0.1 * strength, pow(UV.y, 3.0) * 0.02 * strength)).rgb;
}