shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scenery_mask : filter_linear, repeat_disable;
uniform sampler2D scenery_redraw : filter_nearest, repeat_disable;

void fragment() {
	float scenery = texture(scenery_mask, UV).r;
	vec3 redraw = texture(scenery_redraw, UV).rgb;
	COLOR.rgb = mix(COLOR.rgb, redraw, scenery);
}
