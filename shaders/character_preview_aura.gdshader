shader_type canvas_item;
render_mode unshaded;

// Aura épica detrás del personaje en creación.
// Núcleo radial negro + energía/humo ascendente con ráfagas de viento mágico.
// El centro se actualiza desde GDScript para seguir al personaje (incl. levitación).

uniform vec2 aura_center = vec2(0.5, 0.55); // UV (0-1), actualizado desde script
uniform float aura_radius : hint_range(0.05, 1.0) = 0.28;
// Relación semi-eje horizontal / semi-eje vertical de la elipse.
// < 1.0 = elipse más estrecha que alta (vertical), > 1.0 = más ancha que alta.
uniform float horizontal_squeeze : hint_range(0.1, 2.0) = 0.45;
uniform float core_intensity : hint_range(0.0, 1.0) = 0.88;
uniform float smoke_intensity : hint_range(0.0, 1.0) = 0.7;
uniform float smoke_scale = 4.0;
uniform float time_scale = 0.4;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.8;
uniform float pulse_speed : hint_range(0.0, 4.0) = 1.2;
uniform float pulse_amount : hint_range(0.0, 0.25) = 0.05;
uniform float emanate_strength : hint_range(0.0, 2.0) = 0.8;
uniform vec3 aura_color : source_color = vec3(0.0, 0.0, 0.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.0 + vec2(3.7, 1.3);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = UV;
	vec2 d = p - aura_center;
	// Elipse vertical: comprimimos X para que la elipse sea estrecha y alta,
	// siguiendo la silueta del personaje de pies a cabeza.
	// El viewport es cuadrado (500×500), así que no hace falta corregir aspect ratio.
	float dist = length(vec2(d.x / horizontal_squeeze, d.y));

	float t = TIME * time_scale;
	float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
	float dynamic_radius = aura_radius * (1.0 + (pulse - 0.5) * pulse_amount);

	// Vignette: núcleo oscuro que respira y decae suavemente hacia los bordes.
	float vignette = 1.0 - smoothstep(0.0, dynamic_radius, dist);
	vignette = pow(vignette, 1.5);

	// Capa 1: humo ascendente denso (energía que se eleva).
	vec2 smoke_uv = d * smoke_scale;
	smoke_uv.y += t * 3.5; // += = ascendente (UV.y crece hacia abajo)
	smoke_uv.x += sin(t * 0.6 + p.y * 6.0) * wind_strength * 0.4;
	smoke_uv += normalize(d + 0.0001) * t * emanate_strength * 0.35;
	float smoke = fbm(smoke_uv);
	smoke = smoothstep(0.32, 0.72, smoke);

	// Capa 2: wisp más lento, ancho, con viento cruzado.
	vec2 vapor_uv = d * (smoke_scale * 0.45);
	vapor_uv.y += t * 2.0;
	vapor_uv.x += cos(t * 0.35 + p.y * 4.0) * wind_strength * 0.6;
	vapor_uv += normalize(d + 0.0001) * t * emanate_strength * 0.2;
	float vapor = fbm(vapor_uv);
	vapor = smoothstep(0.40, 0.80, vapor);

	// Capa 3: ráfagas verticales — rayos de energía que suben rápido.
	vec2 gust_uv = vec2(d.x * 12.0 + sin(t * 1.2) * 2.0,
						d.y * 3.0 + t * 5.0);
	float gust = fbm(gust_uv);
	gust = smoothstep(0.55, 0.85, gust);
	// Las ráfagas solo en la columna sobre el personaje, no debajo.
	float vertical_mask = smoothstep(0.0, 0.5, -d.y);
	gust *= vertical_mask;

	float energy = mix(mix(smoke, vapor, 0.5), gust, 0.35);
	float energy_mask = vignette * energy;

	// Falloff vertical: la energía se intensifica arriba del personaje.
	float upward_boost = smoothstep(0.0, dynamic_radius * 0.9, -d.y);
	energy_mask *= 0.5 + 0.5 * upward_boost;

	float alpha = vignette * core_intensity + energy_mask * smoke_intensity;
	// Pulso sutil en la intensidad del núcleo para que la oscuridad "respire".
	alpha *= 1.0 + (pulse - 0.5) * 0.08;
	alpha = clamp(alpha, 0.0, 1.0);

	COLOR = vec4(aura_color, alpha);
}
