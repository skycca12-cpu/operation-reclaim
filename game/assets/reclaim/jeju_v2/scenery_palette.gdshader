shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scenery_mask : filter_linear, repeat_disable;

float brightness(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec4 original = COLOR;
	float scenery = texture(scenery_mask, UV).r;
	if (scenery > 0.002) {
		float value = brightness(original.rgb);
		vec2 dx = vec2(TEXTURE_PIXEL_SIZE.x, 0.0);
		vec2 dy = vec2(0.0, TEXTURE_PIXEL_SIZE.y);
		float surrounding = (
			brightness(texture(TEXTURE, UV - dx).rgb) +
			brightness(texture(TEXTURE, UV + dx).rgb) +
			brightness(texture(TEXTURE, UV - dy).rgb) +
			brightness(texture(TEXTURE, UV + dy).rgb)
		) * 0.25;

		// Widen the form shadows while keeping existing texture and material colors.
		float levels = smoothstep(0.08, 0.86, value);
		float bands = floor(levels * 7.0 + 0.5) / 7.0;
		float edge = clamp((value - surrounding) * 0.80, -0.12, 0.10);
		float light = mix(levels, bands, 0.42) + edge;
		vec3 chroma = (original.rgb - value) * 0.82;
		vec3 shadow = vec3(0.105, 0.069, 0.114);
		vec3 lit = vec3(0.96, 0.85, 0.76);
		vec3 rendered = mix(shadow, lit, clamp(light, 0.0, 1.0)) + chroma;
		COLOR = vec4(mix(original.rgb, clamp(rendered, vec3(0.0), vec3(1.0)), scenery), original.a);
	}
}
