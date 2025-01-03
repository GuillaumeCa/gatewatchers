shader_type spatial;

uniform sampler2D gradient: source_color;
uniform sampler2D base: source_color;
uniform sampler2D flowmap: source_color;
uniform float flow_speed = 1.0;
uniform float flow_intensity = 1.0;



void fragment() {
	vec2 uv = UV * 3.0;
	vec2 flow = texture(flowmap, uv).xy;
	flow = (flow - 0.5) * 2.0;
	float timephase1 = fract(TIME * flow_speed);
	float timephase2 = fract(timephase1 + 0.5);
	float flow_mix = abs((timephase1 - 0.5) * 2.0);

	vec3 main_tex1 = texture(base, uv + (flow * timephase1 * flow_intensity)).rgb;
	vec3 main_tex2 = texture(base, uv + (flow * timephase2 * flow_intensity)).rgb;
	vec3 main_blend = mix(main_tex1, main_tex2, flow_mix);

	float base_albedo = main_blend.r;
	ALBEDO.rgb = texture(gradient, vec2(base_albedo)).rgb * 2.0;
}
