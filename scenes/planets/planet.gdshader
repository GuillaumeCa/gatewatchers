shader_type spatial;


uniform sampler2D gradient: source_color;
uniform sampler2D noise: source_color;
uniform sampler2D noise_macro: source_color;

varying vec3 noise_triplanar_pos;
varying vec3 noise_power_normal;

uniform float noise_blend_sharpness : hint_range(0.0, 150.0, 0.001);
uniform float noise_scale;
uniform vec3 noise_offset;


uniform float terrain_height: hint_range(10.0, 300.0, 5.0) = 10.0;
uniform float water_lvl = 0.2;
uniform float water_h = 0.2;

uniform float precision_level: hint_range(1, 50, 0.1) = 1.0;

uniform float period = 0.1;


varying float terrain_h;

float quantize(float value, float precision) {
    return round(value * precision) / precision;
}


float height(float h) {
	//v = quantize(v, precision_level);
	float v = (1.0 - (h * 2.0 - 1.0));

	if (v < water_lvl) {
		v = water_lvl;
	}

	return v * terrain_height;
}

vec3 orthogonal(vec3 v) {
  return normalize(abs(v.x) > abs(v.z) ? vec3(-v.y, v.x, 0.0)
  : vec3(0.0, -v.z, v.y));
}

//float triplanar_texture(sampler2D tex, vec3 vertex, vec3 normal) {
	//float albedoX = texture(tex, vertex.zy * noise_scale).r;
	//float albedoY = texture(tex, vertex.xz * noise_scale).r;
	//float albedoZ = texture(tex, vertex.xy * noise_scale).r;
	//
	//vec3 blend_weight = pow(abs(normal), vec3(blend_sharpness));
	//blend_weight /= dot(blend_weight, vec3(1.0));
	//
	//return albedoX * blend_weight.x + albedoY * blend_weight.y + albedoZ * blend_weight.z;
//}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

float blend2(float a, float b) {
	return a * 0.7 + b * 0.3;
}

void vertex() {
	vec3 normal = NORMAL;
	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);


	// UV1 Triplanar: Enabled
	noise_power_normal = pow(abs(NORMAL), vec3(noise_blend_sharpness));
 	noise_triplanar_pos = VERTEX * vec3(noise_scale * 0.001) + noise_offset;
	noise_power_normal /= dot(noise_power_normal, vec3(1.0));
	noise_triplanar_pos *= vec3(1.0, -1.0, 1.0);

	float n = triplanar_texture(noise, noise_power_normal, noise_triplanar_pos).r;
	float n_macro = triplanar_texture(noise_macro, noise_power_normal, noise_triplanar_pos).r;
	float h = blend2(n, n_macro);

	float k = height(h);

	vec3 displacedPos = VERTEX + vec3(k) * NORMAL;

	//float offset = 0.1;
	//vec3 tangent = orthogonal(NORMAL);
	//vec3 bitangent = normalize(cross(NORMAL, tangent));
	//vec3 neighbour1 = VERTEX + tangent * offset;
	//vec3 neighbour2 = VERTEX + bitangent * offset;
	//
	//vec3 displacedNeighbour1 = neighbour1 + NORMAL * height(triplanar_texture(noise, noise_power_normal, noise_triplanar_pos + vec3(0.0, 0.01, 0.0)));
	//vec3 displacedNeighbour2 = neighbour2 + NORMAL * height(triplanar_texture(noise, noise_power_normal, noise_triplanar_pos + vec3(0.001, 0.0, 0.0)));
	//vec3 displacedTangent = displacedNeighbour1 - displacedPos;
	//vec3 displacedBitangent = displacedNeighbour2 - displacedPos;


	VERTEX = displacedPos;
	//TANGENT = displacedTangent;
	//BINORMAL = displacedBitangent;
	//NORMAL = normalize(cross(displacedTangent, displacedBitangent));



	//NORMAL = normalize(cross(dx, dy));

	//NORMAL = normalize(vec3(k - height(pos + vec2(0.1, 0.0)), 0.1, k - height(pos + vec2(0.0, 0.1))));
	//NORMAL = texture(noise_normal, uv).rgb;

	// to fix normals ??
	//TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	//TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	//TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	//TANGENT = normalize(TANGENT);
//
	//BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	//BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	//BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	//BINORMAL = normalize(BINORMAL);
}

void fragment() {
	vec2 uv = UV;

	//float v = texture(noise, uv).r;
	float n = triplanar_texture(noise, noise_power_normal, noise_triplanar_pos).r;
	float n_macro = triplanar_texture(noise_macro, noise_power_normal, noise_triplanar_pos).r;

	float h = blend2(n, n_macro);

	h = quantize(h, precision_level);

	vec3 color = texture(gradient, vec2(h, 0.0)).rgb;


	ROUGHNESS = h < water_h ? 1.0 : 0.0;

	ALBEDO.rgb = color;//vec3(water);
	//vec3 n = triplanar_texture(noise_normal, noise_power_normal, noise_triplanar_pos).xyz;
	//NORMAL_MAP = n;
	//NORMAL_MAP_DEPTH = 0.7;

	//NORMAL_MAP = texture(noise_normal, uv).rgb;

	// Called for every pixel the material is visible on.
}