shader_type spatial;
render_mode cull_disabled;

// Generated from HomeLand_Asset/Environment/Forest/Decoration/Road/Material/Mystic/S_Road_Dirt_01_M.shadergraph by tools/art/unity_to_godot/sg2godot.py. Do not edit.

uniform sampler2D sg_white : source_color, hint_default_white;
uniform float p_VariationCycle = 0.0;
uniform float sg_shadow : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D pTexture2D_7ac346ea479446cea0bfe4186f5a27a2 : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform sampler2D pTexture2D_d549b8d6945d44ab93f2b539849b6188 : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform sampler2D pTexture2D_e1c84429c98f4a16a0d097a455ad46f0 : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform sampler2D t_3d94369c6b56 : source_color, repeat_enable, filter_linear_mipmap;
uniform vec3 sg_main_light_dir = vec3(0.6767, 0.6767, -0.2907);
uniform vec4 pColor_c0bef9d824a646a8be04642cb186fb4a : source_color = vec4(0.0, 0.0, 0.0, 0.0);
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
vec3 sg_srgb_to_linear(vec3 c) {
	vec3 lo = c / 12.92;
	vec3 hi = pow((c + 0.055) / 1.055, vec3(2.4));
	return mix(hi, lo, vec3(lessThanEqual(c, vec3(0.04045))));
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
vec4 sg_gradient_0(float t) {
	vec3 color = vec3(1.0, 1.0, 1.0);
	{ float p = clamp((t - 0.4927901029586792) / 0.007217526435852051, 0.0, 1.0); color = mix(color, vec3(0.0, 0.0, 0.0), mix(p, step(0.01, p), 0.0)); }
	{ float p = clamp((t - 0.5000076293945312) / 0.49999237060546875, 0.0, 1.0); color = mix(color, vec3(0.0, 0.0, 0.0), mix(p, step(0.01, p), 0.0)); }
	float alpha = 1.0;
	{ float p = clamp((t - 0.0) / 1.0, 0.0, 1.0); alpha = mix(alpha, 1.0, mix(p, step(0.01, p), 0.0)); }
	return vec4(sg_srgb_to_linear(color), alpha);
}

void vertex() {
	sg_obj_pos = vec3(-VERTEX.x, VERTEX.y, VERTEX.z);
	vec3 v1 = sg_mirror((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v2 = vec4(v1, 1.0);
	vec4 v3 = vec4(v1, 0.0);
	vec2 v4 = vec2(v3.x, v3.z);
	vec4 v5 = vec4(1.0, 0.0, 0.0, 0.0) / vec4(0.4000000059604645, 2.0, 2.0, 2.0);
	vec2 v6 = v4 * (v5).xy;
	float v7 = sg_gnoise(v6 * 0.10000000149011612) + 0.5;
	vec2 v8 = vec2(0.0, 1.0);
	vec2 v9 = vec2(-1.0, 1.0);
	float v10 = v9.x + (v7 - v8.x) * (v9.y - v9.x) / (v8.y - v8.x);
	float v11 = v10 * (vec4(0.41999998688697815, 2.0, 2.0, 2.0)).x;
	float v12 = v11 * 1.0;
	vec3 v13 = sg_mirror((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v14 = vec4(v13, 1.0);
	vec4 v15 = vec4(v13, 0.0);
	float v16 = v12 + v15.x;
	float v17 = v12 + v15.z;
	vec4 v18 = vec4(v16, v15.y, v17, 0.0);
	vec3 v19 = sg_mirror((inverse(MODEL_MATRIX) * vec4(sg_mirror((v18).xyz), 1.0)).xyz);
	VERTEX = sg_mirror(v19);
}

void fragment() {
	vec3 v20 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v21 = vec4(v20, 1.0);
	vec4 v22 = vec4(v20, 0.0);
	vec2 v23 = vec2(v22.x, v22.z);
	float v24 = 0.18000000715255737;
	vec2 v25 = v23 * vec2(v24);
	vec2 v26 = v25 - vec2(0.5, 0.5);
	float v27 = 0.30000001192092896;
	vec2 v28 = vec2(v26.x * cos(v27) + v26.y * sin(v27), -v26.x * sin(v27) + v26.y * cos(v27)) + vec2(0.5, 0.5);
	vec4 v29 = texture(pTexture2D_d549b8d6945d44ab93f2b539849b6188, vec2((v28).x, 1.0 - (v28).y));
	vec4 v30 = texture(pTexture2D_7ac346ea479446cea0bfe4186f5a27a2, vec2(((vec4(UV2.x, 1.0 - UV2.y, 0.0, 0.0)).xy).x, 1.0 - ((vec4(UV2.x, 1.0 - UV2.y, 0.0, 0.0)).xy).y));
	vec3 v31 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v32 = vec4(v31, 1.0);
	vec4 v33 = vec4(v31, 0.0);
	vec2 v34 = vec2(v33.x, v33.z);
	float v35 = 0.04500000178813934;
	vec2 v36 = v34 * vec2(v35);
	vec2 v37 = v36 - vec2(0.5, 0.5);
	float v38 = ((45.0) * 3.14159265359 / 180.0);
	vec2 v39 = vec2(v37.x * cos(v38) + v37.y * sin(v38), -v37.x * sin(v38) + v37.y * cos(v38)) + vec2(0.5, 0.5);
	vec4 v40 = texture(pTexture2D_e1c84429c98f4a16a0d097a455ad46f0, vec2((v39).x, 1.0 - (v39).y));
	float v41 = 0.6499999761581421;
	vec4 v42 = v40 * vec4(v41);
	vec4 v43 = vec4(UV.x, 1.0 - UV.y, 0.0, 0.0);
	vec4 v44 = v43;
	vec4 v45 = sg_gradient_0(v44.x);
	vec4 v46 = v45;
	float v47 = 1.0 - v46.x;
	vec4 v48 = mix(v30, v42, vec4(v47));
	float v49 = mod(p_VariationCycle, 3.0 * 3.0);
	vec2 v50 = vec2(1.0) / vec2(3.0, 3.0);
	float v51 = abs(0.0 * 3.0 - ((v49 - 3.0 * floor(v49 * v50.x)) + 0.0 * 1.0));
	float v52 = abs(1.0 * 3.0 - (floor(v49 * v50.x) + 1.0 * 1.0));
	vec2 v53 = ((vec4(UV.x, 1.0 - UV.y, 0.0, 0.0)).xy + vec2(v51, v52)) * v50;
	vec4 v54 = texture(t_3d94369c6b56, vec2((v53).x, 1.0 - (v53).y));
	vec4 v55 = mix(v29, v48, vec4(v54.z));
	vec3 v56 = (v40).xyz;
	float v57 = dot(v56, vec3(0.2126729, 0.7151522, 0.0721750));
	vec3 v58 = vec3(v57) + vec3(1.159999966621399) * (v56 - vec3(v57));
	float v59 = v54.y * (vec4(0.6000000238418579, 2.0, 2.0, 2.0)).x;
	vec3 v60 = mix((v55).xyz, v58, vec3(v59));
	float v61 = 2.0;
	vec3 v62 = v60 * vec3(v61);
	vec3 v63 = sg_white_balance(v62, -0.20000000298023224, 0.0);
	vec3 v64 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	float v65 = 1.0 - sg_shadow;
	vec3 v66 = mix(v60, v63, vec3(v65));
	ALBEDO = v66;
	ALPHA = v54.x;
	ALPHA_SCISSOR_THRESHOLD = 0.23000000417232513;
	EMISSION = (pColor_c0bef9d824a646a8be04642cb186fb4a).xyz;
	METALLIC = 0.0;
	ROUGHNESS = 1.0 - 0.0;
}
