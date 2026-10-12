shader_type spatial;
render_mode unshaded, cull_disabled;

// Generated from HomeLand_Asset/Environment/Forest/Ground/Source/S_TileGrass_01.shadergraph by tools/art/unity_to_godot/sg2godot.py. Do not edit.

uniform sampler2D sg_white : source_color, hint_default_white;
uniform float sg_shadow : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D t_3add89cad378 : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D t_8fad90633f86 : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D t_9e3315273822 : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D t_a726981f4aae : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D t_bc4145dd4d51 : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D t_d591289b711c : source_color, repeat_enable, filter_linear_mipmap;
uniform vec3 sg_main_light_dir = vec3(0.6767, 0.6767, -0.2907);
uniform vec4 sg_main_light_color : source_color = vec4(1.0);
varying vec3 sg_obj_pos;

vec3 sg_mirror(vec3 v) { return vec3(-v.x, v.y, v.z); }
float sg_hash_tchou(vec2 i) {
	uvec2 v = uvec2(ivec2(round(i)));
	v.y ^= 1103515245u;
	v.x += v.y;
	v.x *= v.y;
	v.x ^= v.x >> 5u;
	v.x *= 0x27d4eb2du;
	return float(v.x) * (1.0 / 4294967295.0);
}
vec2 sg_gnoise_dir_det(vec2 p) {
	float x = sg_hash_tchou(p) * 2.0 - 1.0;
	return normalize(vec2(x - floor(x + 0.5), abs(x) - 0.5));
}
float sg_gnoise_det(vec2 p) {
	vec2 ip = floor(p);
	vec2 fp = fract(p);
	float d00 = dot(sg_gnoise_dir_det(ip), fp);
	float d01 = dot(sg_gnoise_dir_det(ip + vec2(0.0, 1.0)), fp - vec2(0.0, 1.0));
	float d10 = dot(sg_gnoise_dir_det(ip + vec2(1.0, 0.0)), fp - vec2(1.0, 0.0));
	float d11 = dot(sg_gnoise_dir_det(ip + vec2(1.0, 1.0)), fp - vec2(1.0, 1.0));
	fp = fp * fp * fp * (fp * (fp * 6.0 - 15.0) + 10.0);
	return mix(mix(d00, d01, fp.y), mix(d10, d11, fp.y), fp.x);
}
float sg_vnoise_rand_det(vec2 uv) { return sg_hash_tchou(uv); }
float sg_fmod(float x, float y) { return x - y * trunc(x / y); }
vec2 sg_fmod2(vec2 x, vec2 y) { return x - y * trunc(x / y); }
float sg_vnoise_rand(vec2 uv) { return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453); }
float sg_vnoise(vec2 uv, bool det) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	f = f * f * (3.0 - 2.0 * f);
	float r0 = det ? sg_vnoise_rand_det(i) : sg_vnoise_rand(i);
	float r1 = det ? sg_vnoise_rand_det(i + vec2(1.0, 0.0)) : sg_vnoise_rand(i + vec2(1.0, 0.0));
	float r2 = det ? sg_vnoise_rand_det(i + vec2(0.0, 1.0)) : sg_vnoise_rand(i + vec2(0.0, 1.0));
	float r3 = det ? sg_vnoise_rand_det(i + vec2(1.0, 1.0)) : sg_vnoise_rand(i + vec2(1.0, 1.0));
	return mix(mix(r0, r1, f.x), mix(r2, r3, f.x), f.y);
}
float sg_simple_noise(vec2 uv, float scale, bool det) {
	float t = 0.0;
	for (int i = 0; i < 3; i++) {
		float freq = pow(2.0, float(i));
		float amp = pow(0.5, float(3 - i));
		t += sg_vnoise(uv * scale / freq, det) * amp;
	}
	return t;
}
vec2 sg_gnoise_dir(vec2 p) {
	p = sg_fmod2(p, vec2(289.0));
	float x = sg_fmod((34.0 * p.x + 1.0) * p.x, 289.0) + p.y;
	x = sg_fmod((34.0 * x + 1.0) * x, 289.0);
	x = fract(x / 41.0) * 2.0 - 1.0;
	return normalize(vec2(x - floor(x + 0.5), abs(x) - 0.5));
}
float sg_gnoise(vec2 p) {
	vec2 ip = floor(p);
	vec2 fp = fract(p);
	float d00 = dot(sg_gnoise_dir(ip), fp);
	float d01 = dot(sg_gnoise_dir(ip + vec2(0.0, 1.0)), fp - vec2(0.0, 1.0));
	float d10 = dot(sg_gnoise_dir(ip + vec2(1.0, 0.0)), fp - vec2(1.0, 0.0));
	float d11 = dot(sg_gnoise_dir(ip + vec2(1.0, 1.0)), fp - vec2(1.0, 1.0));
	fp = fp * fp * fp * (fp * (fp * 6.0 - 15.0) + 10.0);
	return mix(mix(d00, d01, fp.y), mix(d10, d11, fp.y), fp.x);
}
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define half float
#define half2 vec2
#define half3 vec3
#define half4 vec4
#define int2 ivec2
#define int3 ivec3
#define lerp mix
#define frac fract
#define rsqrt inversesqrt
#define saturate(x) clamp((x), 0.0, 1.0)
#define fmod(a, b) ((a) - (b) * trunc((a) / (b)))
#define atan2(y, x) atan((y), (x))
vec3 sg_white_balance(vec3 col, float temperature, float tint) {
	float t1 = temperature * 10.0 / 6.0;
	float t2 = tint * 10.0 / 6.0;
	float x = 0.31271 - t1 * (t1 < 0.0 ? 0.1 : 0.05);
	float std_y = 2.87 * x - 3.0 * x * x - 0.27509507;
	float y = std_y + t2 * 0.05;
	vec3 w1 = vec3(0.949237, 1.03542, 1.08728);
	float Y = 1.0;
	float X = Y * x / y;
	float Z = Y * (1.0 - x - y) / y;
	float L = 0.7328 * X + 0.4296 * Y - 0.1624 * Z;
	float M = -0.7036 * X + 1.6975 * Y + 0.0061 * Z;
	float S = 0.0030 * X + 0.0136 * Y + 0.9834 * Z;
	vec3 balance = w1 / vec3(L, M, S);
	mat3 lin_2_lms = mat3(vec3(3.90405e-1, 5.49941e-1, 8.92632e-3), vec3(7.08416e-2, 9.63172e-1, 1.35775e-3), vec3(2.31082e-2, 1.28021e-1, 9.36245e-1));
	mat3 lms_2_lin = mat3(vec3(2.85847, -1.62879, -2.48910e-2), vec3(-2.10182e-1, 1.15820, 3.24281e-4), vec3(-4.18120e-2, -1.18169e-1, 1.06867));
	vec3 lms = col * lin_2_lms;
	lms *= balance;
	return lms * lms_2_lin;
}
void sg_cf_GroundPathTile_0(float scaleX, float scaleY, float scaleZ, out float OutX, out float OutY, out float OutZ) {
OutY = clamp(floor(floor(abs(scaleY*100.0 - floor(scaleY*100.0))*100.0 + 0.1)),0.0,15.1);
OutZ = clamp(floor(floor(abs(scaleZ*1000.0 - floor(scaleZ*1000.0))*10.0 + 0.1)),0.0,4.1);
OutX = clamp(floor(floor(abs(scaleX*1000.0 - floor(scaleX*1000.0))*10.0 + 0.1)),0.0,1.1);
}
void sg_cf_mapChange_0(vec4 forest, vec4 arctic, vec4 savannah, vec4 mystic, vec4 genesis, float lerpInt, out vec4 Out) {
Out = lerp(lerp(lerp(lerp(forest, arctic, lerpInt), savannah, floor(lerpInt/2.0)), mystic, floor(lerpInt/3.0)), genesis, floor(lerpInt/4.0));
}

void vertex() {
	sg_obj_pos = vec3(-VERTEX.x, VERTEX.y, VERTEX.z);
}

void fragment() {
	vec3 v1 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v2 = vec4(v1, 1.0);
	vec4 v3 = vec4(v1, 0.0);
	vec2 v4 = vec2(v3.x, v3.z);
	float v5 = 0.013000000268220901;
	vec2 v6 = v4 * vec2(v5);
	vec2 v7 = v6 * vec2(1.0, 0.6499999761581421) + vec2(0.0, 0.0);
	vec4 v8 = texture(t_9e3315273822, vec2((v7).x, 1.0 - (v7).y));
	vec3 v9 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v10 = vec4(v9, 1.0);
	vec4 v11 = vec4(v9, 0.0);
	vec2 v12 = vec2(v11.x, v11.z);
	float v13 = 2.3399999141693115;
	vec2 v14 = v12 - vec2(0.5, 0.5);
	float v15 = v13;
	vec2 v16 = vec2(v14.x * cos(v15) + v14.y * sin(v15), -v14.x * sin(v15) + v14.y * cos(v15)) + vec2(0.5, 0.5);
	vec2 v17 = vec2(0.029999999329447746, 0.014999999664723873);
	vec2 v18 = v16 * v17;
	vec4 v19 = texture(t_bc4145dd4d51, vec2((v18).x, 1.0 - (v18).y));
	vec3 v20 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v21 = vec4(v20, 1.0);
	vec4 v22 = vec4(v20, 0.0);
	vec2 v23 = vec2(v22.x, v22.z);
	vec2 v24 = vec2(0.029999999329447746, 0.014999999664723873);
	vec2 v25 = v23 * v24;
	vec4 v26 = texture(t_8fad90633f86, vec2((v25).x, 1.0 - (v25).y));
	vec3 v27 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v28 = vec4(v27, 1.0);
	vec4 v29 = vec4(v27, 0.0);
	vec2 v30 = vec2(v29.x, v29.z);
	float v31 = 0.5400000214576721;
	vec2 v32 = v30 - vec2(0.5, 0.5);
	float v33 = v31;
	vec2 v34 = vec2(v32.x * cos(v33) + v32.y * sin(v33), -v32.x * sin(v33) + v32.y * cos(v33)) + vec2(0.5, 0.5);
	vec2 v35 = vec2(0.029999999329447746, 0.029999999329447746);
	vec2 v36 = v34 * v35;
	vec4 v37 = texture(t_3add89cad378, vec2((v36).x, 1.0 - (v36).y));
	vec4 v38 = texture(t_a726981f4aae, vec2((v18).x, 1.0 - (v18).y));
	vec4 v39 = vec4(0.6523787347979056, 0.31329586064205384, 0.008645322150652952, 0.5529412031173706);
	vec4 v40 = v38;
	vec4 v41 = v39;
	vec3 v42 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec2 v43 = (vec4(v42, 1.0)).xz;
	float v44 = 0.10000000149011612;
	vec2 v45 = v43 * vec2(v44) + vec2(0.0, 0.0);
	float v46 = sg_simple_noise(v45, 1.0, false);
	vec2 v47 = vec2(0.0, 1.0);
	float v48 = 8.0;
	float v49 = v48 * (vec4(-1.0, 2.0, 2.0, 2.0)).x;
	vec2 v50 = vec2(v49, v48);
	vec2 v51 = v50;
	float v52 = v51.x + (v46 - v47.x) * (v51.y - v51.x) / (v47.y - v47.x);
	float v53 = TIME * (vec4(0.10000000149011612, 2.0, 2.0, 2.0)).x;
	vec2 v54 = v43 * vec2(1.0, 1.0) + vec2(v53);
	float v55 = sg_simple_noise(v54, 1.0, false);
	float v56 = v52 + v55;
	float v57 = sg_gnoise(vec2(v56) * 10.0) + 0.5;
	float v58 = smoothstep((vec4(0.8700000047683716, 0.0, 0.0, 0.0)).x, (vec4(0.9100000262260437, 1.0, 1.0, 1.0)).x, v57);
	float v59 = 0.029999999329447746;
	vec2 v60 = v43 * vec2(v59) + vec2(0.0, 0.0);
	vec4 v61 = texture(t_d591289b711c, vec2((v60).x, 1.0 - (v60).y));
	float v62 = smoothstep((vec4(0.10000000149011612, 0.0, 0.0, 0.0)).x, (vec4(0.5, 1.0, 1.0, 1.0)).x, v61.x);
	float v63 = v58 + v62;
	float v64 = clamp(v63, 0.0, 1.0);
	float v65 = (v39).w;
	float v66 = v64 * v65;
	vec4 v67 = v41;
	vec4 v68 = mix(v40, v67, v66);
	vec4 v69 = vec4(2.0, 0.9882352948188782, 0.0, 1.0);
	vec4 v70 = v68;
	vec4 v71 = v69;
	float v72 = 0.5;
	float v73 = TIME * v72;
	float v74 = sin(v73);
	vec2 v75 = vec2(-1.0, 1.0);
	vec2 v76 = vec2(0.0, 1.0);
	float v77 = v76.x + (v74 - v75.x) * (v76.y - v76.x) / (v75.y - v75.x);
	float v78 = sg_simple_noise(v43, 0.5, false);
	float v79 = v77 - v78;
	float v80 = abs(v79);
	vec2 v81 = vec2(0.0, 1.0);
	vec2 v82 = vec2(0.5, 3.0);
	vec2 v83 = v82;
	float v84 = v83.x + (v80 - v81.x) * (v83.y - v83.x) / (v81.y - v81.x);
	float v85 = v84 + (vec4(0.10000000149011612, 0.0, 0.0, 0.0)).x;
	float v86 = smoothstep(v84, v85, v57);
	float v87 = v64 * v86;
	float v88 = TIME * (vec4(2.0, 2.0, 2.0, 2.0)).x;
	vec2 v89 = (vec4(UV.x, 1.0 - UV.y, 0.0, 0.0)).xy * vec2(1.0, 1.0) + vec2(v88);
	float v90 = sg_gnoise(v89 * 0.10000000149011612) + 0.5;
	vec2 v91 = vec2(0.0, 1.0);
	vec2 v92 = vec2(-0.5, 0.5);
	float v93 = v92.x + (v90 - v91.x) * (v92.y - v92.x) / (v91.y - v91.x);
	float v94 = clamp(v93, 0.0, 1.0);
	float v95 = v94 * v64;
	float v96 = v87 + v95;
	float v97 = v64 * v96;
	float v98 = v97 - 0.0;
	float v99 = clamp(v98, 0.0, 1.0);
	vec4 v100 = v71;
	vec4 v101 = mix(v70, v100, v99);
	vec4 v102 = v38;
	vec4 v103 = v69;
	vec4 v104 = v103;
	vec4 v105 = mix(v102, v104, v99);
	vec3 v106 = sg_mirror(MODEL_MATRIX[3].xyz);
	vec3 v107 = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec4 v108 = vec4(v107, 1.0);
	vec4 v109 = vec4(v107, 0.0);
	float v110;
	float v111;
	float v112;
	sg_cf_GroundPathTile_0(v109.x, v109.y, v109.z, v110, v111, v112);
	vec4 v113;
	sg_cf_mapChange_0(v8, v19, v26, v37, v101, v112, v113);
	float v114 = 0.10000000149011612;
	vec4 v115 = v113 * vec4(v114);
	vec3 v116 = sg_white_balance((v115).xyz, -1.2000000476837158, 0.0);
	vec3 v117 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	float v118 = pow(sg_shadow, (vec4(1.5, 2.0, 2.0, 2.0)).x);
	float v119 = 1.0 - v118;
	vec3 v120 = mix((v113).xyz, v116, vec3(v119));
	ALBEDO = v120;
}
