shader_type canvas_item;

uniform vec4 core_rect = vec4(455.0, 170.0, 541.0, 413.0);
uniform vec2 overlay_size = vec2(1451.0, 753.0);
uniform vec4 fog_color : source_color = vec4(0.0157, 0.0196, 0.0274, 0.84);
uniform float inner_falloff = 52.0;
uniform float outer_falloff = 240.0;

void fragment() {
	vec2 pixel = UV * overlay_size;
	vec2 core_min = core_rect.xy;
	vec2 core_max = core_rect.xy + core_rect.zw;
	float dx = max(max(core_min.x - pixel.x, 0.0), pixel.x - core_max.x);
	float dy = max(max(core_min.y - pixel.y, 0.0), pixel.y - core_max.y);
	float distance_to_core = length(vec2(dx, dy));
	if (distance_to_core <= 0.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		return;
	}
	float fog_factor = smoothstep(inner_falloff, outer_falloff, distance_to_core);
	COLOR = vec4(fog_color.rgb, fog_color.a * fog_factor);
}
