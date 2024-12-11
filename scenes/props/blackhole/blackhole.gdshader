shader_type spatial;
render_mode unshaded, cull_front, specular_disabled;

uniform float event_horizon_radius : hint_range(0.0, 10.0) = 0.075;
uniform vec4 accretion_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float accretion_density : hint_range(0.0, 1000.0) = 200.0;
uniform float accretion_thickness : hint_range(0.0, 5.0) = 0.05;
uniform float accretion_radius : hint_range(0.0, 100.0) = 0.5;
uniform float accretion_inner_radius : hint_range(0.0, 50.0) = 0.1;
uniform float opacity : hint_range(0.0, 100.0) = 0.5;

uniform float step_size : hint_range(0.0, 10.0, 0.001) = 0.1;
uniform float step_size_mult : hint_range(1.0, 100000.0, 1) = 10.0;
uniform float step_size_max : hint_range(1.0, 100000.0, 1) = 10.0;
uniform int max_steps = 128;
uniform float depth_thickness : hint_range(0.0, 0.1) = 0.057;
uniform bool use_depth = true;
uniform float max_radius : hint_range(0.5, 10.0) = 0.5;


uniform float global_radius: hint_range(0.1, 100.0, 0.1) = 0.5;

uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

uniform vec3 pos;


vec2 sphere_intersection(vec3 ro, vec3 rd, vec3 sph_pos, float radius) {
	vec3 oc = ro - sph_pos;
	float b = dot(oc, rd);
	float c = dot(oc, oc) - radius * radius;
	float h = b * b - c;
	if (h < 0.0) return vec2(-1.0);
	h = sqrt(h);
	return vec2(-b - h, -b + h);
}

float bh_strength(float radius) {
	return pow(radius / 0.75, 3.0);
}

float size() {
	return global_radius / 50.0;
}

vec3 bh_force(float dist, vec3 p) {
	return -1.5 * bh_strength(event_horizon_radius) * p * pow(dist, -5.0) * smoothstep(20.3, 0.3, dist); // to make space flat outside the region
}

float accretion_disk(float dist, float z) {
	float h = accretion_thickness * size();
	float R = accretion_radius  * size();
	float r = accretion_inner_radius  * size();
	float heigh_weight = exp(-pow(z/h, 2));
	float rad_weight = exp(-dist/R) * smoothstep(0.05, 1.0, 1.0 - dist / R) * smoothstep(r, r*1.2, dist);
	return accretion_density * heigh_weight * rad_weight;
}

float grad_noise(vec2 uv) {
	return fract(52.73856769017 * fract(0.0644787296*float(uv.x) + 0.005893891 *float(uv.y)));
}

varying vec3 world_pos;

void vertex() {
	vec3 vtx = VERTEX;
	world_pos = (MODEL_MATRIX * vec4(vtx, 1.0)).xyz + pos;
}

float remap(float value, float low1, float high1, float low2, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment() {
    vec3 camera_position = CAMERA_POSITION_WORLD + pos;
    vec3 ray_direction = normalize(world_pos - camera_position);
    
	//camera_position += ray_direction;
	
    vec3 rv = ray_direction;
    vec3 ro = camera_position;
    
    float accretion_rho = 0.0;
    float accretion_color_intensity = 0.0;
    bool hit_horizon = false;
    bool stopped = false;
	
	float steps = 0.0;

	// adjust step size to make it match with the distance between the black hole and the camera
	float cam_dist = length(camera_position - world_pos);
	float adjusted_step_size = clamp(cam_dist * 1.0/step_size_mult, step_size, step_size_max); //remap(cam_dist, 100.0, 10000.0, step_size, 10.0); //4.0;//clamp(step_size + cam_dist /step_size_mult, step_size, 10.0);
	float dt = adjusted_step_size; //adjusted_step_size;

    for (int j = 0; j < max_steps; j++) {
        
        float dist = length(ro) - global_radius;

        if (dist < global_radius * 1.5) {
            float rho = accretion_disk(dist, ro.y) * 0.08;
            accretion_rho += opacity * rho * dt;
            float opacity_factor = exp(-accretion_rho);
            accretion_color_intensity += rho * dt * opacity_factor;

            rv += bh_force(dist, ro) * dt;
        }
        
        ro += rv * dt;

        if (dist - global_radius / 40.0 < event_horizon_radius) {
            hit_horizon = true;
			steps = float(j);
            break;
        }
        //if (dist > max_radius){// || accretion_rho > 32.0) {
            //break;
        //}

        if (use_depth) {
            // Depth check placeholder: In Godot, this might need to be adjusted to access depth textures
            // float depth_scene = ... (use `DEPTH_TEXTURE` if available or similar approach)
        }
    }
    
    vec3 screen_pos = (PROJECTION_MATRIX * vec4(ro, 1.0)).xyz;
    float accretion_opacity = 1.0 - exp(-accretion_rho);

    vec4 background = textureLod(screen_texture, SCREEN_UV, 0.0) *  (1.0 - float(hit_horizon));
    vec4 accretionColor = accretion_color * accretion_color_intensity;
    
    ALBEDO = mix(background.rgb, accretionColor.rgb, accretion_opacity);
    ALPHA = 1.0;
}
