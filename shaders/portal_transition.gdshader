shader_type canvas_item;

// 0.0 -> inicio | 1.0 -> final
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 portal_color : source_color = vec4(0.64, 0.30, 0.95, 1.0);
uniform vec4 white_glow : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 portal_center = vec2(0.5, 0.5);
uniform float swirl_speed : hint_range(0.0, 10.0) = 2.2;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float star_field(vec2 uv, float t) {
	float s = 0.0;
	for (int i = 0; i < 22; i++) {
		float fi = float(i);
		vec2 p = vec2(
			hash(vec2(fi, 1.7)) * 0.9 + 0.05,
			hash(vec2(3.1, fi)) * 0.9 + 0.05
		);
		float tw = 0.45 + 0.55 * sin(t * 3.0 + fi * 1.37);
		float d = length(uv - p);
		s += smoothstep(0.02, 0.0, d) * tw;
	}
	return clamp(s, 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV;
	vec2 c = portal_center;
	vec2 d = uv - c;
	float r = length(d);
	float a = atan(d.y, d.x);

	// Curvas suaves para evitar cortes abruptos
	float t_enter = smoothstep(0.0, 0.45, progress);
	float t_peak = smoothstep(0.20, 0.75, progress);
	float t_release = smoothstep(0.60, 1.0, progress);

	// Luz que nace del portal y baña toda la pantalla
	float wave_radius = mix(0.03, 1.15, t_enter);
	float wave = 1.0 - smoothstep(wave_radius - 0.22, wave_radius + 0.18, r);

	// Núcleo brillante alrededor del portal
	float core = 1.0 - smoothstep(0.0, 0.14 + 0.20 * t_peak, r);

	// Remolino violeta fluido
	float swirl = sin(a * 3.0 + r * 24.0 - TIME * swirl_speed) * 0.5 + 0.5;
	float fluid = sin((uv.x + uv.y) * 18.0 + TIME * 1.8) * 0.5 + 0.5;
	float swirl_mask = (1.0 - smoothstep(0.0, 0.75, r));
	float violet_flow = swirl_mask * (0.45 * swirl + 0.55 * fluid) * t_peak;

	// Estrellas élficas suaves durante la fase media
	float stars = star_field(uv + vec2(TIME * 0.015, -TIME * 0.012), TIME) * (1.0 - t_release) * t_peak;

	// Blanco mágico envolvente + ráfaga final suave
	float white_layer = wave * (0.65 + 0.25 * t_peak) + core * 0.85;
	float bloom = smoothstep(0.35, 0.85, progress) * (1.0 - t_release * 0.6);

	vec3 col = vec3(0.0);
	col += white_glow.rgb * (white_layer + bloom * 0.55);
	col += portal_color.rgb * (violet_flow * 0.9 + core * 0.22);
	col += vec3(1.0, 0.97, 0.92) * stars;

	// Fade-out fluido para revelar mapa nuevo
	float fade_out = 1.0 - smoothstep(0.82, 1.0, progress);
	float alpha = clamp((white_layer * 0.85 + violet_flow * 0.45 + stars * 0.5), 0.0, 1.0) * fade_out;

	COLOR = vec4(col, alpha);
}
