shader_type sky;

uniform vec4 base_color: source_color;

group_uniforms Stars;
uniform float luminosity: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform sampler2D star_gradient: hint_default_black;

uniform float star_height = 5.;
uniform float star_blend = .1;
uniform float depth_blend = .1;
uniform float star_size = 5.;
uniform int star_layers = 5;
uniform float flare_ratio: hint_range(0.0, 1.0, 0.01) = .2;
group_uniforms;

group_uniforms Nebula;
uniform sampler2D nebula_texture: hint_default_black;
uniform sampler2D nebula_mask: hint_default_black;
uniform vec4 nebula_primary: source_color;
uniform vec4 nebula_secondary: source_color;
uniform int nebula_layers = 1;
uniform float nebula_scale: hint_range(0.0, 0.1, 0.001) = 0.1;
uniform float nebula_blend = 0.5;
uniform float nebula_power = 1.0;
uniform float nebula_seed = 1.0;
group_uniforms;

vec2 random_vec2(vec2 seed) {
	vec2 s = fract(seed * vec2(123.45, 453.45));
	s += dot(s, s * 784.34);
	float x = fract(s.x * 134.45);
	float y = fract(s.y * 853.18);
	return vec2(x, y) - .5;
}

vec2 rotate_uv(vec2 uv, float rotation) {
    float mid = 0.5;
    return vec2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

float star(vec2 uv, float flare) {
	float s = .005 / length(uv);
	float rays = max(0, 1. - abs(uv.x * uv.y) * 1000.0) * s;
	s += rays * flare;
	return clamp(pow(s, 1.8), 0.0, 1.);
}

vec3 star_layer(vec2 uv) {
	vec2 uv_grid = fract(uv) - .5;
	vec2 grid_id = floor(uv);

	vec3 s = vec3(0.0);
	for (float y = -1.; y <= 1.; y++) {
		for (float x = -1.; x <= 1.; x++) {
			vec2 offset = vec2(x, y);
			vec2 rv = random_vec2(grid_id + offset);
			float size = (rv.x + .5) * star_size;
			//size += sin(TIME * 10. + rv.x * 2.) * star_size * 0.02;
			float flare = smoothstep(star_size * (1. - flare_ratio), star_size, size);
			vec3 star_color = texture(star_gradient, vec2(rv.y)).rgb;
			s += star(uv_grid - rv - offset , flare) * size * star_color * luminosity * .5;
		}
	}

	return s;
}

vec3 create_stars(vec2 uv, float blend) {

	vec3 s = vec3(0.0);
	for (float i = 1.; i <= float(star_layers); i++) {
		uv += random_vec2(vec2(i, i + 34.)) * i * 4.4;
		s += star_layer(uv * i) * blend;
	}

	return s;
}

float create_nebula(vec2 uv) {
	float nebula = texture(nebula_texture, uv).r;
	float mask = texture(nebula_mask, uv - 0.2).r;
	nebula *= mask;
	nebula = pow(nebula, nebula_power);
	return nebula;
}


void sky() {
	if (AT_CUBEMAP_PASS) {
        // Sets the radiance cubemap to a nice shade of blue instead of doing
        // expensive sky calculations
        COLOR = base_color.rgb;
    } else {
		float blend = smoothstep(star_blend, 1, abs(EYEDIR.y));
		float depth_curve = pow(abs(EYEDIR.y), depth_blend);
		vec2 uv = (EYEDIR.xz / (depth_curve + 0.01)) * star_height;
		uv.x = min(uv.x, 100000.0);
		uv.y = min(uv.y, 100000.0);

		// Do expensive sky calculations for background sky only
        COLOR = create_stars(uv, blend);

		vec4 nebula = vec4(0.0);

		for (float i = 1.; i <= float(nebula_layers); i++) {
			vec2 ruv = rotate_uv(uv, EYEDIR.y * .4);
			vec2 rd = random_vec2(ruv);
			nebula += vec4(create_nebula(ruv * nebula_scale + i * 0.3 + nebula_seed));
			float m = texture(nebula_mask, 2.0 + uv * .2).r;
			vec3 nebula_color = mix(nebula_primary.rgb, nebula_secondary.rgb, m);
			nebula.rgb = nebula.r * nebula_color.rgb;
		}
		nebula.rgb *= smoothstep(0, nebula_blend, abs(EYEDIR.y));
		FOG = nebula;
		//FOG = vec4(color_mask);
    }
}
