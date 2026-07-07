shader_type canvas_item;
render_mode unshaded;

// Aura que envuelve la silueta completa del personaje (cuerpo + cabeza).
// Lee screen_texture (el personaje ya renderizado en el SubViewport) y dilata
// su alfa para construir un halo con falloff + humo FBM ascendente.
// Solo dibuja FUERA de la silueta (alfa 0 sobre el personaje) => el personaje
// se ve por encima y el halo parece estar detrás.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float halo_radius : hint_range(4.0, 60.0) = 26.0; // px (en resolución del viewport)
uniform float halo_intensity : hint_range(0.0, 1.0) = 0.92;
uniform float halo_falloff : hint_range(0.5, 4.0) = 1.6;
uniform float smoke_intensity : hint_range(0.0, 1.0) = 0.55;
uniform float smoke_scale = 5.0;
uniform float time_scale = 0.35;
uniform vec3 halo_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 smoke_tint : source_color = vec3(0.20, 0.09, 0.26);
uniform float sample_step = 2.5; // paso del muestreo para la distancia a la silueta

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

// Distancia aproximada a la silueta opaca más cercana (en píxeles del viewport).
float dist_to_silhouette(vec2 uv) {
	float min_dist = halo_radius;
	for (float x = -halo_radius; x <= halo_radius; x += sample_step) {
		for (float y = -halo_radius; y <= halo_radius; y += sample_step) {
			float a = texture(screen_texture, uv + vec2(x, y) * SCREEN_PIXEL_SIZE).a;
			if (a > 0.5) {
				min_dist = min(min_dist, length(vec2(x, y)));
			}
		}
	}
	return min_dist;
}

void fragment() {
	float charA = texture(screen_texture, UV).a;

	// Sobre el personaje: no dibujar nada (deja ver el personaje que ya está renderizado).
	if (charA > 0.5) {
		COLOR = vec4(0.0);
		return;
	}

	float d = dist_to_silhouette(UV);
	if (d >= halo_radius) {
		COLOR = vec4(0.0);
		return;
	}

	// Halo con falloff: 1 en la silueta, 0 en halo_radius.
	float halo = 1.0 - smoothstep(0.0, halo_radius, d);
	halo = pow(halo, halo_falloff);

	// Humo ascendente (energía que se eleva) en espacio de pantalla, enmascarado por el halo.
	float t = TIME * time_scale;
	vec2 smoke_uv = UV * smoke_scale;
	smoke_uv.y += t * 2.0;
	smoke_uv.x += sin(t * 0.5 + UV.y * 8.0) * 0.3;
	float smoke = fbm(smoke_uv);
	smoke = smoothstep(0.35, 0.78, smoke);

	// Segunda capa: wisp más lento y ancho.
	vec2 vapor_uv = UV * (smoke_scale * 0.5);
	vapor_uv.y += t * 1.1;
	vapor_uv.x += cos(t * 0.3) * 0.4;
	float vapor = fbm(vapor_uv);
	vapor = smoothstep(0.42, 0.82, vapor);

	float smoke_combined = mix(smoke, vapor, 0.5);
	float smoke_mask = halo * smoke_combined;

	float alpha = halo * halo_intensity + smoke_mask * smoke_intensity;
	alpha = clamp(alpha, 0.0, 1.0);

	// Todo en negro: el humo no tinta, solo aporta opacidad.
	vec3 col = halo_color;

	COLOR = vec4(col, alpha);
}
