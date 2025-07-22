shader_type spatial;

uniform vec4 color: source_color;
uniform sampler2D surface_noise: filter_linear_mipmap, hint_default_black;

uniform float intensity = 1.0;
uniform float dark_spot = 1.0;

uniform float start;
uniform float end;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 surfcolor = color.rgb;
	
	float d1 = texture(surface_noise, 0.03 * TIME + UV * 10.0).r;
	float d2 = texture(surface_noise, 0.04 * TIME - UV * 10.0).r;
	
	surfcolor -= d1 * d2 * dark_spot;
	
	ALBEDO = surfcolor;
	EMISSION = surfcolor * intensity;
}