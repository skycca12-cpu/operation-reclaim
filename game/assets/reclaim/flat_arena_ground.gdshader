shader_type canvas_item;
render_mode unshaded;

uniform float repeats = 8.0;

void fragment() {
	COLOR = texture(TEXTURE, fract(UV * repeats));
}
