shader_type canvas_item;
render_mode unshaded;

uniform float repeats;

vec3 ground_patch(sampler2D ground, vec2 pixel_size, vec2 sample_point, vec2 cell) {
	// Rotate successive samples so distinctive cracks do not form mirrored pairs.
	vec2 local = sample_point - cell - 0.5;
	float turn = mod(cell.x + 3.0 * cell.y + floor(cell.y * 0.5), 4.0);
	if (turn > 2.5) {
		local = vec2(local.y, -local.x);
	} else if (turn > 1.5) {
		local = -local;
	} else if (turn > 0.5) {
		local = vec2(-local.y, local.x);
	}
	vec2 source_pixel = vec2(815.0, 608.0) + local * 100.0;
	return texture(ground, source_pixel * pixel_size).rgb;
}

void fragment() {
	// Cross-fade only near joins; each sample stays within the bare asphalt crop.
	vec2 point = UV * repeats;
	vec2 first = floor(point - 0.5);
	vec2 weight = smoothstep(vec2(0.42), vec2(0.58), fract(point - 0.5));
	vec3 top = mix(ground_patch(TEXTURE, TEXTURE_PIXEL_SIZE, point, first),
		ground_patch(TEXTURE, TEXTURE_PIXEL_SIZE, point, first + vec2(1.0, 0.0)), weight.x);
	vec3 bottom = mix(ground_patch(TEXTURE, TEXTURE_PIXEL_SIZE, point, first + vec2(0.0, 1.0)),
		ground_patch(TEXTURE, TEXTURE_PIXEL_SIZE, point, first + vec2(1.0, 1.0)), weight.x);
	COLOR = vec4(mix(top, bottom, weight.y), 1.0);
}
