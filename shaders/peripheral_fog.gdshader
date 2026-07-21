shader_type canvas_item;

uniform float fog_intensity : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	vec2 core_min = vec2(0.3577, 0.1832);
	vec2 core_max = vec2(0.6423, 0.8166);
	float dx = max(max(core_min.x - UV.x, 0.0), UV.x - core_max.x);
	float dy = max(max(core_min.y - UV.y, 0.0), UV.y - core_max.y);
	float dist = length(vec2(dx, dy));
	float fog = smoothstep(0.0, 0.15, dist);
	COLOR = vec4(0.02, 0.03, 0.05, fog * fog_intensity);
}
