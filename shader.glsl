/* src:
https://inspirnathan.com/posts/52-shadertoy-tutorial-part-6
*/

const float RAYMIN = 0.0;
const float RAYMAX = 100.0;
const int RAYSTEP = 255;
const float PREC_RAY = 0.001; //precision of the ray

const vec3 BACK_COLOR = vec3(0.8);
const vec3 LIGHT_POS = vec3(2., 2., 4.);
const float GI_SIM = 0.4; //global illumination simulation (between 0. and 1.)

const float M_PI = 3.14159265358979323846;
const float FLT_MAX = 3.402823466e+38;

vec3 A = vec3(-1,-1,0);
vec3 B = vec3(1,-1,0);
vec3 C = vec3(0,1,0);
vec3 D = vec3(0,0,-1);

uint uhash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

float rand( uint x ) {
    return float(uhash(x)) / float(0xffffffff);
}

vec3 spherical2cartesian(float theta, float phi, float r){
    return vec3(r * sin(theta) * cos(phi),
                r * sin(theta) * sin(phi),
                r * cos(theta));
}


vec4 dist_sphere(vec3 p, vec3 center, float r, vec3 color){
    return vec4(length(p - center) - r, color);
}

vec4 guingangou(vec3 p, vec3 color)
{
    //float d = length(p) - 1.;
    float dA = distance(p, A);
    float dB = distance(p, B);
    float dC = distance(p, C);
    float dD = distance(p, D);

    float dAB = abs(dA - dB);
    float dAC = abs(dA - dC);
    float dAD = abs(dA - dD);
    float dBC = abs(dB - dC);
    float dBD = abs(dB - dD);
    float dCD = abs(dC - dD);

    float d = (dAB + dAC + dAD + dBC + dBD + dCD) - (sin(1.) + 1.) * 0.1;

    return vec4(d, color);
}

vec4 guingangougan(vec3 p, vec3 color)
{
    float dmin = FLT_MAX;
    uint rnd = 3u;
    for(int i=0; i<10; i++){
        rnd = uhash(rnd);
        float theta = (float(rnd) / float(0xffffffff)) * (M_PI / 2.);
        rnd = uhash(rnd);
        float phi = (float(rnd) / float(0xffffffff)) * (M_PI * 2.);

        vec3 pi = spherical2cartesian(theta, phi, 1.);
        float di = distance(p, pi) - 0.05;
        dmin = di < dmin ? di : dmin;
    }
    return vec4(dmin, color);
}

vec4 sdScene(vec3 p){
    vec4 dmin = vec4(FLT_MAX, vec3(0));
    //vec4 d0   = dist_sphere(p, A, 0.1, vec3(1., 1., 0.));
    //dmin = d0.x < dmin.x ? d0 : dmin;
    //vec4 d1     = dist_sphere(p, B, 0.1, vec3(1., 1., 0.));
    //dmin = d1.x < dmin.x ? d1 : dmin;
    //vec4 d2     = dist_sphere(p, C, 0.1, vec3(1., 1., 0.));
    //dmin = d2.x < dmin.x ? d2 : dmin;
    //vec4 d3     = dist_sphere(p, D, 0.1, vec3(1., 1., 0.));
    //dmin = d3.x < dmin.x ? d3 : dmin;
    
    vec4 dhex = guingangou(p, vec3(1., 0., 0.));
    dmin = dhex.x < dmin.x ? dhex : dmin;

    vec4 drnd = guingangougan(p, vec3(0., 0., 1.));
    dmin = drnd.x < dmin.x ? drnd : dmin;

    return dmin;
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0005; // epsilon
    return normalize(
      e.xyy * sdScene(p + e.xyy).x +
      e.yyx * sdScene(p + e.yyx).x +
      e.yxy * sdScene(p + e.yxy).x +
      e.xxx * sdScene(p + e.xxx).x);
}


/*  ro: ray origin 
    rd: ray direction (normalized)*/
vec4 ray(vec3 ro, vec3 rd){
    vec3 p;
    float depth = RAYMIN;
    
    for(int i=0; i<RAYSTEP; i++){
        p = ro + depth*rd;
        vec4 vtmp = sdScene(p);
        float dist = vtmp.x;
        depth += dist;
        if(dist < PREC_RAY || depth > RAYMAX) return vec4(depth, vtmp.yzw);
    }
    return vec4(depth, BACK_COLOR);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy - 0.5;
    uv.x *= iResolution.x/iResolution.y;
    
    vec3 ro = vec3(0., 0., 5.);
    vec3 rd = normalize(vec3(uv.x, uv.y, -1));
    vec4 vtmp = ray(ro, rd);
    float dist = vtmp.x;

    vec3 color_final = BACK_COLOR;
    if(dist < RAYMAX){
        vec3 color_obj = vtmp.yzw;
        vec3 pi = ro + dist*rd;
        vec3 pi_normal = calcNormal(pi);
        
        vec3 lightdir = normalize(LIGHT_POS - pi);
        float difuse_light = clamp(dot(pi_normal, lightdir), 0., 1.);
        
        //color_final = mix(color_obj*GI_SIM, color_obj, difuse_light);
        color_final = mix(vec3(0.), color_obj, difuse_light);
    }
    
    fragColor = vec4(color_final, 1.);
}

