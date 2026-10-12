shader_type spatial;
render_mode unshaded, cull_disabled;

// Generated from HomeLand_Asset/Environment/Savannah/Ground/Source/S_TileGrass_234_S.shadergraph by tools/art/unity_to_godot/sg2godot.py. Do not edit.

uniform sampler2D sg_white : source_color, hint_default_white;
uniform float pVector1_289664510415420d9e12f44557522d07 = 3.200000047683716;
uniform float pVector1_37c9937e6ef8422894b7fbbebb6a2d08 = 0.5899999737739563;
uniform float sg_shadow : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D pTexture2D_2e7207a153524759864e018b20a36b59 : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform sampler2D pTexture2D_f296769a84014f6988cf8d206fe42724 : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform vec3 sg_main_light_dir = vec3(0.6767, 0.6767, -0.2907);
uniform vec4 sg_main_light_color : source_color = vec4(1.0);
varying vec3 sg_obj_pos;

vec3 sg_mirror(vec3 v) { return vec3(-v.x, v.y, v.z); }
float sg_fmod(float x, float y) { return x - y * trunc(x / y); }
vec2 sg_fmod2(vec2 x, vec2 y) { return x - y * trunc(x / y); }
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

void vertex() {
	sg_obj_pos = vec3(-VERTEX.x, VERTEX.y, VERTEX.z);
	vec3 v1 = sg_mirror((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 v2 = sg_mirror((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v3 = vec4(v2, 1.0);
	vec4 v4 = vec4(v2, 0.0);
	vec2 v5 = vec2(v4.x, v4.z);
	vec2 v6 = vec2(2.4000000953674316, 0.0);
	vec2 v7 = vec2(TIME) * v6;
	vec2 v8 = v5 * vec2(0.3499999940395355, 0.25) + v7;
	float v9 = sg_gnoise(v8 * 0.41999998688697815) + 0.5;
	float v10 = v9 - (vec4(0.5, 1.0, 1.0, 1.0)).x;
	float v11 = v10 * pVector1_37c9937e6ef8422894b7fbbebb6a2d08;
	vec3 v12 = sg_mirror((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v13 = vec4(v12, 1.0);
	vec4 v14 = vec4(v12, 0.0);
	float v15 = v11 + v14.x;
	vec4 v16 = vec4(v15, v14.y, v14.z, 0.0);
	vec4 v17 = vec4(UV.x, 1.0 - UV.y, 0.0, 0.0);
	vec4 v18 = v17;
	vec3 v19 = mix(v1, (v16).xyz, vec3(v18.y));
	vec3 v20 = sg_mirror((inverse(MODEL_MATRIX) * vec4(sg_mirror(v19), 1.0)).xyz);
	float v21 = 1.0 - v18.y;
	float v22 = mix(v11, (vec4(0.0, 1.0, 1.0, 1.0)).x, v21);
	float v23 = clamp(v22, (vec4(0.0, 0.0, 0.0, 0.0)).x, (vec4(0.029999999329447746, 1.0, 1.0, 1.0)).x);
	VERTEX = sg_mirror(v20);
}

void fragment() {
	vec3 v24 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 v25 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v26 = vec4(v25, 1.0);
	vec4 v27 = vec4(v25, 0.0);
	vec2 v28 = vec2(v27.x, v27.z);
	vec2 v29 = vec2(2.4000000953674316, 0.0);
	vec2 v30 = vec2(TIME) * v29;
	vec2 v31 = v28 * vec2(0.3499999940395355, 0.25) + v30;
	float v32 = sg_gnoise(v31 * 0.41999998688697815) + 0.5;
	float v33 = v32 - (vec4(0.5, 1.0, 1.0, 1.0)).x;
	float v34 = v33 * pVector1_37c9937e6ef8422894b7fbbebb6a2d08;
	vec3 v35 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v36 = vec4(v35, 1.0);
	vec4 v37 = vec4(v35, 0.0);
	float v38 = v34 + v37.x;
	vec4 v39 = vec4(v38, v37.y, v37.z, 0.0);
	vec4 v40 = vec4(UV.x, 1.0 - UV.y, 0.0, 0.0);
	vec4 v41 = v40;
	vec3 v42 = mix(v24, (v39).xyz, vec3(v41.y));
	vec3 v43 = sg_mirror((inverse(MODEL_MATRIX) * vec4(sg_mirror(v42), 1.0)).xyz);
	float v44 = 1.0 - v41.y;
	float v45 = mix(v34, (vec4(0.0, 1.0, 1.0, 1.0)).x, v44);
	float v46 = clamp(v45, (vec4(0.0, 0.0, 0.0, 0.0)).x, (vec4(0.029999999329447746, 1.0, 1.0, 1.0)).x);
	float v47 = v46 + (vec4(1.0, 0.0, 0.0, 0.0)).x;
	vec3 v48 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v49 = vec4(v48, 1.0);
	vec4 v50 = vec4(v48, 0.0);
	vec2 v51 = vec2(v50.x, v50.z);
	vec2 v52 = vec2(0.029999999329447746, 0.014999999664723873);
	vec2 v53 = v51 * v52;
	vec4 v54 = texture(pTexture2D_2e7207a153524759864e018b20a36b59, vec2((v53).x, 1.0 - (v53).y));
	float v55 = 0.10000000149011612;
	vec4 v56 = v54 * vec4(v55);
	vec3 v57 = sg_white_balance((v56).xyz, -1.2000000476837158, 0.0);
	vec3 v58 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	float v59 = pow(sg_shadow, (vec4(1.5, 2.0, 2.0, 2.0)).x);
	float v60 = 1.0 - v59;
	vec3 v61 = mix((v54).xyz, v57, vec3(v60));
	vec3 v62 = v61 * vec3(pVector1_289664510415420d9e12f44557522d07);
	vec3 v63 = sg_white_balance(v62, 1.2000000476837158, 0.0);
	vec4 v64 = texture(pTexture2D_f296769a84014f6988cf8d206fe42724, vec2(((vec4(UV.x, 1.0 - UV.y, 0.0, 0.0)).xy).x, 1.0 - ((vec4(UV.x, 1.0 - UV.y, 0.0, 0.0)).xy).y));
	vec3 v65 = mix(v61, v63, vec3(v64.y));
	vec3 v66 = vec3(v47) * v65;
	ALBEDO = v66;
	ALPHA = v64.x;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
