shader_type spatial;
render_mode unshaded, cull_disabled;

// Generated from HomeLand_Asset/Environment/Savannah/Ground/Source/S_LandPlot_Savannah.shadergraph by tools/art/unity_to_godot/sg2godot.py. Do not edit.

uniform sampler2D sg_white : source_color, hint_default_white;
uniform float pVector1_d286a9a95ecc4e2f976cc2b14d3c2cff = -0.7400000095367432;
uniform float sg_shadow : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D pTexture2D_3e79e3fd56a44863875da278ba8e1dfc : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
uniform sampler2D t_2aa0348f00fe : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D t_54815ad5a35c : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D t_de8b3b94650f : source_color, repeat_enable, filter_linear_mipmap;
uniform vec3 sg_main_light_dir = vec3(0.6767, 0.6767, -0.2907);
uniform vec4 sg_main_light_color : source_color = vec4(1.0);
varying vec3 sg_obj_pos;

vec3 sg_mirror(vec3 v) { return vec3(-v.x, v.y, v.z); }
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
	{ float p = clamp((t - 0.8947890400886536) / 0.07919430732727051, 0.0, 1.0); color = mix(color, vec3(0.0, 0.0, 0.0), mix(p, step(0.01, p), 0.0)); }
	{ float p = clamp((t - 0.9739833474159241) / 0.026016652584075928, 0.0, 1.0); color = mix(color, vec3(0.0, 0.0, 0.0), mix(p, step(0.01, p), 0.0)); }
	float alpha = 1.0;
	{ float p = clamp((t - 0.0) / 1.0, 0.0, 1.0); alpha = mix(alpha, 1.0, mix(p, step(0.01, p), 0.0)); }
	return vec4(sg_srgb_to_linear(color), alpha);
}
vec4 sg_gradient_1(float t) {
	vec3 color = vec3(1.0, 1.0, 1.0);
	{ float p = clamp((t - 0.9457083940505981) / 0.004531919956207275, 0.0, 1.0); color = mix(color, vec3(0.8450000286102295, 0.8450000286102295, 0.8450000286102295), mix(p, step(0.01, p), 0.0)); }
	{ float p = clamp((t - 0.9502403140068054) / 0.010589778423309326, 0.0, 1.0); color = mix(color, vec3(0.0, 0.0, 0.0), mix(p, step(0.01, p), 0.0)); }
	float alpha = 1.0;
	{ float p = clamp((t - 0.0) / 1.0, 0.0, 1.0); alpha = mix(alpha, 1.0, mix(p, step(0.01, p), 0.0)); }
	return vec4(sg_srgb_to_linear(color), alpha);
}

void vertex() {
	sg_obj_pos = vec3(-VERTEX.x, VERTEX.y, VERTEX.z);
}

void fragment() {
	vec4 v1 = vec4(1.0, 0.9130986568361682, 0.7083757955467578, 0.0);
	vec3 v2 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v3 = vec4(v2, 1.0);
	vec4 v4 = vec4(v2, 0.0);
	vec2 v5 = vec2(v4.x, v4.z);
	float v6 = 0.02500000037252903;
	vec2 v7 = v5 * vec2(v6);
	vec2 v8 = v7 - vec2(0.5, 0.5);
	float v9 = 0.30000001192092896;
	vec2 v10 = vec2(v8.x * cos(v9) + v8.y * sin(v9), -v8.x * sin(v9) + v8.y * cos(v9)) + vec2(0.5, 0.5);
	vec4 v11 = texture(t_2aa0348f00fe, vec2((v10).x, 1.0 - (v10).y));
	float v12 = v11.z * (vec4(0.15000000596046448, 2.0, 2.0, 2.0)).x;
	vec4 v13 = mix(vec4(0.0, 0.0, 0.0, 0.0), v1, vec4(v12));
	vec4 v14 = texture(t_54815ad5a35c, vec2((v10).x, 1.0 - (v10).y));
	vec4 v15 = v13 + v14;
	vec3 v16 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v17 = vec4(v16, 1.0);
	vec4 v18 = vec4(v16, 0.0);
	vec2 v19 = vec2(v18.x, v18.z);
	vec2 v20 = vec2(0.029999999329447746, 0.014999999664723873);
	vec2 v21 = v19 * v20;
	vec4 v22 = texture(pTexture2D_3e79e3fd56a44863875da278ba8e1dfc, vec2((v21).x, 1.0 - (v21).y));
	vec4 v23 = vec4(UV.x, 1.0 - UV.y, 0.0, 0.0);
	vec4 v24 = v23;
	vec4 v25 = sg_gradient_0(v24.y);
	vec3 v26 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec4 v27 = vec4(v26, 1.0);
	vec4 v28 = vec4(v26, 0.0);
	vec2 v29 = vec2(v28.x, v28.z);
	float v30 = 0.07000000029802322;
	vec2 v31 = v29 * vec2(v30);
	vec4 v32 = texture(t_de8b3b94650f, vec2((v31).x, 1.0 - (v31).y));
	float v33 = pow(v32.x, pVector1_d286a9a95ecc4e2f976cc2b14d3c2cff);
	vec4 v34 = v25 * vec4(v33);
	vec4 v35 = clamp(v34, vec4(0.0, 0.0, 0.0, 0.0), vec4(1.0, 1.0, 1.0, 1.0));
	vec4 v36 = sg_gradient_1(v24.y);
	vec4 v37 = v35 * v36;
	vec4 v38 = mix(v15, v22, v37);
	float v39 = 0.10000000149011612;
	vec4 v40 = v38 * vec4(v39);
	vec3 v41 = sg_white_balance((v40).xyz, -1.2000000476837158, 0.0);
	vec3 v42 = sg_mirror((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	float v43 = pow(sg_shadow, (vec4(1.5, 2.0, 2.0, 2.0)).x);
	float v44 = 1.0 - v43;
	vec3 v45 = mix((v38).xyz, v41, vec3(v44));
	ALBEDO = v45;
}
