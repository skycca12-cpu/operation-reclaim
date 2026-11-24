shader_type canvas_item;

uniform vec2 viewport_size;
uniform vec2 map_center;
uniform float zoom = 1.0;
uniform float world_half_extent = 1080.0;

void fragment() {
	vec2 screen_point = SCREEN_UV * viewport_size;
	vec2 world_point = abs((screen_point - map_center) / zoom);
	float from_edge = world_half_extent - max(world_point.x, world_point.y);
	COLOR.a *= smoothstep(0.0, 115.0, from_edge);
}
