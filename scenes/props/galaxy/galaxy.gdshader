shader_type spatial;
render_mode unshaded;

uniform sampler2D depth_texture : source_color, hint_depth_texture;


// Created by sebastien durand - 08/2016
//-------------------------------------------------------------------------------------
// Based on "Dusty nebula 4" by Duke (https://www.shadertoy.com/view/MsVXWW) 
// Sliders from IcePrimitives by Bers (https://www.shadertoy.com/view/MscXzn)
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
//-------------------------------------------------------------------------------------
#define R(p, a) p=cos(a)*p+sin(a)*vec2(p.y, -p.x)
#define pi 3.14159265

uniform sampler2D noise;

uniform vec4 color_center: source_color = vec4(1.2, 1.5,1.5,.25);
uniform vec4 color_edge: source_color = vec4(.1,.1,.2,.5);
uniform vec4 color_edge2: source_color = vec4(.7,.54,.3,.23);
uniform vec4 color_edge3: source_color = vec4(.6,1.,1.3,.25);
uniform float spin_speed: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float scale = 1.0;

uniform float r1 = 0.1;
uniform float r2 = 0.1;
uniform float r3 = 0.1;

vec2 min2(vec2 a, vec2 b) {
    return a.x<b.x ? a  : b;
}

float hash( const in vec3 p ) {
	float h = dot(p,vec3(127.1,311.7,758.5453123));	
    return fract(sin(h)*43758.5453123);
}

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// [iq] https://www.shadertoy.com/view/4sfGzS
float noiseText(in vec3 x) {
    vec3 p = floor(x), f = fract(x);
	f = f*f*(3.-f-f);
	vec2 uv = (p.xy+vec2(37.,17.)*p.z) + f.xy,
	     rg = vec2(texture(noise, (uv+.5)/256.).r, texture(noise, (uv+5789.25)/256.).r);
	return mix(rg.x, rg.y, f.z);
}

// ratio: ratio of hight/low frequencies
float fbmdust(in vec3 p, in float ratio) {
    return mix(noiseText(p*3.), noiseText(p*20.), ratio);
}

vec2 spiralArm(in vec3 p, in float thickness, in float blurAmout, in float blurStyle) {
    float dephase = 2.2, loop = 4.;
    float a = atan(p.x,p.z),  // angle     
		  r = length(p.xz), lr = log(r), // distance to center
    	  th = (.1-.25*r), // thickness according to distance
    	  d = fract(.5*(a-lr*loop)/pi); //apply rotation and scaling.
    d = (.5/dephase - abs(d-.5))*2.*pi*r;
  	d *= (1.-lr)/thickness;  // space fct of distance
    // Perturb distance field
    float radialBlur = blurAmout*fbmdust(vec3(r*4.,10.*d,10.-5.*p.y),blurStyle);
    return vec2(sqrt(d*d+10.*p.y*p.y/thickness)-th*r*.2-radialBlur);
}

vec2 dfGalaxy(in vec3 p, in float thickness, in float blurAmout, in float blurStyle) {
	return min2(spiralArm(p,                  thickness, blurAmout, blurStyle),
    			spiralArm(vec3(p.z,p.y,-p.x), thickness, blurAmout, blurStyle));  
}

vec2 map(float time, in vec3 p) {
	R(p.xz, spin_speed * (.008*pi+time*.3));
    return dfGalaxy(p, clamp(10. * r1,.9,10.), r2, r3);
}

//--------------------------------------------------------------

// assign color to the media
vec4 computeColor(in vec3 p, in float density, in float radius, in float id) {
	// color based on density alone, gives impression of occlusion within
	// the media
	vec4 result = mix( vec4(1.,.9,.8,1.), vec4(.4,.15,.1,1.), density );
	// color added to the media
	result *= mix( color_center,
                  mix(color_edge2, 
                      mix(color_edge, color_edge3, step(.08,id)), step(-.05,id)),
                  smoothstep(.2,.8,radius) );
	return result;
}

// - Ray / Shapes Intersection -----------------------
bool sBox( in vec3 ro, in vec3 rd, in vec3 rad, out float tN, out float tF)  {
    vec3 m = 1./rd, n = m*ro,
    	k = abs(m)*rad,
        t1 = -n - k, t2 = -n + k;
	tN = max( max( t1.x, t1.y ), t1.z );
	tF = min( min( t2.x, t2.y ), t2.z );
	return !(tN > tF || tF < 0.);
}

bool sSphere(in vec3 ro, in vec3 rd, in float r, out float tN, out float tF) {
	float b = dot(rd, ro), d = b*b - dot(ro, ro) + r;
	if (d < 0.) return false;
	tN = -b - sqrt(d);
	tF = -tN-b-b;
	return tF > 0.;
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

// ---------------------------------------------------
// Based on "Dusty nebula 4" by Duke (https://www.shadertoy.com/view/MsVXWW) 
void fragment() {
	float time = TIME;
	float depth = texture(depth_texture, SCREEN_UV, 0.0).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 camera = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1);
	
    vec4 upos = INV_PROJECTION_MATRIX* vec4(SCREEN_UV * 2.0 - 1.0, depth,1.0);
    vec3 pixel_position = upos.xyz/upos.w;

	// ray origin
	vec3 ro = INV_VIEW_MATRIX[3].xyz;
	
	// ray direction
	vec3 rd = normalize(camera.xyz);
	
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(pixel_position, 1.0)).xyz;
	float world_depth = length(world_pos - ro);  // Distance in world space
	
	// ld, td: local, total density 
	// w: weighting factor
	float ld=0., td=0., w=0.;

	// t: length of the ray
	// d: distance function
	float d=1., t=0.;
    
    const float h = 0.1;
   
	vec4 sum = vec4(0);
   
    float min_dist=0.,  max_dist=0.,
          min_dist2=0., max_dist2=0.;
		
    
	vec3 sun_light = vec3(0.0);
	
    if(sSphere(ro, rd, 4., min_dist, max_dist)) {
		
        if (sBox(ro, rd, vec3(4.,1.8,4.), min_dist2, max_dist2)) {
			
        	
			min_dist = max(.1,max(min_dist, min_dist2));
            max_dist = min(max_dist, max_dist2);
            
            t = min_dist*step(t,min_dist) + .1;//*hash(rd+time);
			
            
            // raymarch loop
            vec4 col;        
            for (int i=0; i<100; i++) {
                vec3 pos = ro + t*rd;
				
				
				if (t > world_depth) discard;


                // Loop break conditions.
                if(td > .9 || sum.a > .99 || t > max_dist) break;

	

                // evaluate distance function
                vec2 res = map(time, pos);
                d = max(res.x,.01);
				
				
                // point light calculations
                vec3 ldst = pos;
                ldst.y*=1.6;
                vec3 ldst2 = pos;
                ldst2.y*=3.6;
                float lDist = max(length(ldst),.1), //max(length(ldst), 0.001);
				      lDist2 = max(length(ldst2),.1);
                // star in center
                vec3 lightColor = (1.-smoothstep(3.,4.5,lDist*lDist))*
                    mix(.015*vec3(1.,.5,.25)/(lDist*lDist),
                        .02*vec3(.5,.7,1.)/(lDist2*lDist2), 
                        smoothstep(.1,2.,lDist*lDist));
                sum.rgb += lightColor; //.015*lightColor/(lDist*lDist); // star itself and bloom around the light
				sun_light += lightColor;
                sum.a += .003/(lDist*lDist);;

                if (d<h) {
                    // compute local density 
                    ld = h - d;
                    // compute weighting factor 
                    w = (1. - td) * ld;
                    // accumulate density
                    td += w + 1./60.;
                    // get color of object (with transparencies)
                    col = computeColor(pos, td,lDist*2., res.y);
                    col.a *= td;
                    // colour by alpha
                    col.rgb *= col.a;
                    // alpha blend in contribution
                    sum += col*(1.0 - sum.a);  
                }
  
                //float pitch = t/iResolution.x;
                //float dt = max(d * 0.25, .005); //pitch);
                // trying to optimize step size near the camera and near the light source
                t += max(d * .15 * max(min(length(ldst), length(ro)),1.0), 0.005);
				
				
                td += .1/70.;
                //t += dt;
            }
            // simple scattering
            sum *= 1. / exp( ld * .2 )*.8 ;  
            sum = clamp( sum, 0., 1. );
    	}
    }
        
	// Background color
    //sum.rgb += vec3(clamp(2.*cos(.5*TIME),0.,.4))*(1. - sum.a)*pow(16.0*q.x*q.y*(1.-q.x)*(1.-q.y),.3);  
 
    //Apply slider overlay
	ALBEDO = sum.rgb;
	//ALBEDO = vec3(world_depth / 10.0);  // Normalize depth to [0,1]
	EMISSION = sun_light.rgb * 1.0;
	
	ALPHA = sum.a;
}
