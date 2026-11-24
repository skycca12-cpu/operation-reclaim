shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scenery_mask : filter_linear, repeat_disable;

void fragment() {
	vec4 original = COLOR;
	float scenery = texture(scenery_mask, UV).r;
	float value = dot(original.rgb, vec3(0.2126, 0.7152, 0.0722));
	float shade = 1.0 - smoothstep(0.18, 0.68, value);
	float highlight = smoothstep(0.32, 0.85, value);
	vec3 graded = mix(vec3(value), original.rgb, 0.76);
	graded = (graded - 0.45) * 1.10 + 0.45;
	graded += shade * vec3(0.035, -0.019, 0.042);
	graded += highlight * vec3(0.025, -0.022, -0.034);
	COLOR = vec4(mix(original.rgb, clamp(graded, vec3(0.0), vec3(1.0)), scenery), original.a);
}
