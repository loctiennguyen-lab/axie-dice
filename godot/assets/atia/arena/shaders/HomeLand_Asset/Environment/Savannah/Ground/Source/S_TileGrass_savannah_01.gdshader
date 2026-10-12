shader_type spatial;
render_mode unshaded, cull_disabled;

// Generated from HomeLand_Asset/Environment/Savannah/Ground/Source/S_TileGrass_savannah_01.shadergraph by tools/art/unity_to_godot/sg2godot.py. Do not edit.

uniform sampler2D sg_white : source_color, hint_default_white;
uniform float pVector1_accdc7198b3b48109e4ec52e10198f83 = -1.2000000476837158;
uniform float sg_shadow : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D pTexture2D_9ae3a7428cce439ea36c6913f36412a4 : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform vec3 sg_main_light_dir = vec3(0.6767, 0.6767, -0.2907);
uniform vec4 sg_main_light_color : source_color = vec4(1.0);
varying vec3 sg_obj_pos;

vec3 sg_mirror(vec3 v) { return vec3(-v.x, v.y, v.z); }
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
}

void fragment() {
	vec3 v1 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v2 = vec4(v1, 1.0);
	vec4 v3 = vec4(v1, 0.0);
	vec2 v4 = vec2(v3.x, v3.z);
	vec2 v5 = vec2(0.029999999329447746, 0.014999999664723873);
	vec2 v6 = v4 * v5;
	vec4 v7 = texture(pTexture2D_9ae3a7428cce439ea36c6913f36412a4, vec2((v6).x, 1.0 - (v6).y));
	float v8 = 0.10000000149011612;
	vec4 v9 = v7 * vec4(v8);
	vec3 v10 = sg_white_balance((v9).xyz, pVector1_accdc7198b3b48109e4ec52e10198f83, 0.0);
	vec3 v11 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	float v12 = pow(sg_shadow, (vec4(1.5, 2.0, 2.0, 2.0)).x);
	float v13 = 1.0 - v12;
	vec3 v14 = mix((v7).xyz, v10, vec3(v13));
	ALBEDO = v14;
}
