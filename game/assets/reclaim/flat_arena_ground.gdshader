shader_type canvas_item;
render_mode unshaded;
uniform float repeats;

void fragment() {
	// Sample only the existing bare asphalt below the helipad.
	// Mirror each repeat so no road lines, landmarks, or seams enter the arena.
	vec2 repeat_position = UV * repeats;
	vec2 mirrored = 1.0 - abs(mod(repeat_position, 2.0) - 1.0);
	vec2 source_pixel = vec2(755.5, 548.5) + mirrored * 119.0;
	COLOR = texture(TEXTURE, source_pixel * TEXTURE_PIXEL_SIZE);
}
