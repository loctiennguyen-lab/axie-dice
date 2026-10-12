shader_type spatial;
render_mode cull_disabled;

// Generated from HomeLand_Asset/Environment/Forest/Decoration/StonePath/Floor/S_StoneFloor.shadergraph by tools/art/unity_to_godot/sg2godot.py. Do not edit.

uniform sampler2D sg_white : source_color, hint_default_white;
uniform float pVector1_9c1ef250afa4424cbe2d88f0a965501f = 3.0;
uniform float pVector1_f0b1a6efd0914380bb8a758541a4e280 = 0.0;
uniform float sg_shadow : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D pTexture2D_0e6d9756e0854b53aa49fb6961de47e5 : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform sampler2D pTexture2D_5891cfed490c406abc436294d6fd7f74 : hint_normal, repeat_enable, filter_linear_mipmap;
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
	float v1 = mod(pVector1_f0b1a6efd0914380bb8a758541a4e280, pVector1_9c1ef250afa4424cbe2d88f0a965501f * pVector1_9c1ef250afa4424cbe2d88f0a965501f);
	vec2 v2 = vec2(1.0) / vec2(pVector1_9c1ef250afa4424cbe2d88f0a965501f, pVector1_9c1ef250afa4424cbe2d88f0a965501f);
	float v3 = abs(0.0 * pVector1_9c1ef250afa4424cbe2d88f0a965501f - ((v1 - pVector1_9c1ef250afa4424cbe2d88f0a965501f * floor(v1 * v2.x)) + 0.0 * 1.0));
	float v4 = abs(1.0 * pVector1_9c1ef250afa4424cbe2d88f0a965501f - (floor(v1 * v2.x) + 1.0 * 1.0));
	vec2 v5 = ((vec4(UV.x, 1.0 - UV.y, 0.0, 0.0)).xy + vec2(v3, v4)) * v2;
	vec4 v6 = texture(pTexture2D_0e6d9756e0854b53aa49fb6961de47e5, vec2((v5).x, 1.0 - (v5).y));
	float v7 = 0.6000000238418579;
	vec4 v8 = v6 * vec4(v7);
	vec3 v9 = sg_white_balance((v8).xyz, -0.20000000298023224, 0.0);
	vec3 v10 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	float v11 = 1.0 - sg_shadow;
	vec3 v12 = mix((v6).xyz, v9, vec3(v11));
	vec4 v13 = texture(pTexture2D_5891cfed490c406abc436294d6fd7f74, vec2((v5).x, 1.0 - (v5).y));
	vec4 v14 = vec4(normalize(vec3(v13.xy * 2.0 - 1.0, sqrt(max(0.0, 1.0 - dot(v13.xy * 2.0 - 1.0, v13.xy * 2.0 - 1.0))))), 1.0);
	vec4 v15 = vec4(-v14.x, v14.y, v14.z, 1.0);
	ALBEDO = v12;
	ALPHA = v6.w;
	ALPHA_SCISSOR_THRESHOLD = 0.800000011920929;
	METALLIC = 0.0;
	ROUGHNESS = 1.0 - 0.0;
	NORMAL_MAP = vec3(-((v15).xyz).x, ((v15).xyz).y, ((v15).xyz).z) * 0.5 + 0.5;
}
