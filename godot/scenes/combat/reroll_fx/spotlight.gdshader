shader_type canvas_item;
// Full-screen dim with a soft round hole that follows the last spinning die.
// Put on a ColorRect covering the viewport. `center` and `radius` are in the rect's pixels.

uniform vec2 rect_size = vec2(1920.0, 1080.0);
uniform vec2 center = vec2(960.0, 430.0);
uniform float radius = 140.0;
uniform float softness = 90.0;
uniform float darkness : hint_range(0.0, 1.0) = 0.62;
uniform vec4 rim_color : source_color = vec4(1.0, 0.843, 0.416, 0.25);
uniform float fade : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = UV * rect_size;
	float d = distance(p, center);
	float dim = smoothstep(radius, radius + softness, d);
	// thin warm rim just inside the edge of the hole, like the design's inset glow
	float rim = smoothstep(radius - 36.0, radius, d) * (1.0 - dim);
	vec3 col = mix(vec3(0.024, 0.031, 0.047), rim_color.rgb, rim * (1.0 - dim));
	float a = max(dim * darkness, rim * rim_color.a);
	COLOR = vec4(col, a * fade);
}
