shader_type canvas_item;
// Painted-plate colour grade — the "texture filter" half of the handoff's background formula
// (`design_handoff_axie_dice_ui/README.md` §Background formula: `saturate(1.05) brightness(.82)`,
// Combat `saturate(1.02) brightness(.74)`).
//
// WHY A SHADER AND NOT A CanvasItemMaterial. The spec says CanvasItemMaterial, but that resource
// exposes blend mode, light mode and particle animation only — it has no brightness and no
// saturation. `modulate` alone would cover brightness and cannot do saturation at all. This is
// the smallest node that produces the two numbers the formula actually asks for, and it is one
// multiply plus one mix per pixel.
//
// Deliberately NOT here: the scrim. That is a separate TextureRect carrying a GradientTexture2D
// stacked above this one, because the scrim is directional and per-screen while the grade is
// the same operation everywhere. Baking the scrim in would make every screen need its own
// shader variant.

uniform float brightness : hint_range(0.0, 2.0) = 0.82;
uniform float saturation : hint_range(0.0, 2.0) = 1.05;

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	// Rec. 709 luma — the same weights the CSS `saturate()` filter matrix uses, so the Godot
	// result and the HTML mockup land on the same colour rather than merely "close".
	float luma = dot(src.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 graded = mix(vec3(luma), src.rgb, saturation) * brightness;
	COLOR = vec4(graded, src.a) * COLOR;
}
