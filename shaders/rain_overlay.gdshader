shader_type canvas_item;
render_mode unshaded;

// ============================================
// === COLORES CONFIGURABLES (Debug Visual) ===
// ============================================

uniform vec4 rain_color_front : source_color = vec4(1.0, 1.0, 1.0, 0.5);  // BLANCO - Gotas frontales (grandes, rápidas)
uniform vec4 rain_color_mid : source_color = vec4(1.0, 1.0, 1.0, 0.7);    // BLANCO - Gotas medias
uniform vec4 rain_color_back : source_color = vec4(1.0, 1.0, 1.0, 1.0);   // BLANCO - Gotas traseras (pequeñas, lentas)
uniform vec4 splash_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);      // BLANCO - Salpicaduras en el suelo
uniform vec4 lightning_color : source_color = vec4(0.8, 0.0, 1.0, 1.0);   // VIOLETA - Relámpagos
uniform vec4 droplet_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);     // ROJO - Gotitas en pantalla

// ============================================
// === APARIENCIA / TAMAÑO (Debug Visual)   ===
// ============================================

uniform float rain_thickness : hint_range(0.4, 2.0) = 5.0;   // Grosor de las líneas de lluvia
uniform float rain_length : hint_range(0.4, 2.0) = 1.0;      // Longitud de las gotas

// ============================================
// === COMPORTAMIENTO DE LA LLUVIA          ===
// ============================================

uniform float rain_density : hint_range(0.0, 1.0) = 0.4;     // Cantidad de gotas
uniform float rain_speed : hint_range(0.1, 3.0) = 1.5;       // Velocidad de caída
uniform float rain_angle : hint_range(-0.5, 0.5) = 0.1;      // Inclinación por viento
uniform float wind_strength : hint_range(0.0, 1.0) = 0.3;    // Fuerza del viento

// ============================================
// === EFECTOS ADICIONALES                  ===
// ============================================

uniform float splash_intensity : hint_range(0.0, 1.0) = 0.6;     // Intensidad de salpicaduras
uniform float drip_intensity : hint_range(0.0, 1.0) = 0.4;       // Gotitas en pantalla
uniform float lightning_flash : hint_range(0.0, 1.0) = 0.0;      // Flash de relámpago
uniform float lightning_intensity : hint_range(0.0, 1.0) = 0.5;  // Intensidad de rayos
uniform float lightning_frequency : hint_range(0.0, 2.0) = 0.3;  // Frecuencia de rayos

// ============================================
// === REFERENCIAS DEL MUNDO (Auto-set)     ===
// ============================================

uniform vec2 world_offset = vec2(0.0, 0.0);
uniform float world_scale = 0.003;

// Hash functions for procedural noise
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

// Smooth noise for organic movement
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

// Main falling raindrops - multiple layers for depth (world-space)
float raindrops(vec2 uv, vec2 world_uv, float t, float layer, float velocity_modifier) {
	float scale = mix(20.0, 50.0, layer);
	// Velocidad base + modificador por movimiento del jugador
	// velocity_modifier > 0 (caminando hacia arriba) = gotas más lentas
	// velocity_modifier < 0 (caminando hacia abajo) = gotas más rápidas
	float velocity_factor = clamp(1.0 - velocity_modifier * 0.9, 0.35, 2.0);
	float speed = mix(0.8, 1.6, layer) * rain_speed * velocity_factor;
	float thickness = mix(0.035, 0.018, layer) * rain_thickness;
	float length_factor = mix(0.45, 0.25, layer) * rain_length;
	
	// Use world coordinates for rain position (doesn't move with camera)
	vec2 p = world_uv;
	p.x += p.y * rain_angle;
	
	// Wind effect varies by layer (parallax)
	float wind_phase = t * 0.3 + layer * 2.1;
	p.x += sin(wind_phase) * wind_strength * 0.15 * (1.0 - layer * 0.5);
	
	float column = floor(p.x * scale);
	
	// Better randomization using multiple hash inputs
	float col_seed = column + layer * 173.7;
	float column_hash = hash(vec2(col_seed, layer * 100.0 + 7.31));
	float speed_var = mix(0.6, 1.4, hash(vec2(col_seed * 1.31, layer * 50.0)));
	
	// Horizontal jitter per column (more random positioning)
	float x_jitter = (hash(vec2(col_seed, 99.9)) - 0.5) * 0.6;
	
	float y_offset = t * speed * speed_var + column_hash * 17.0;
	float row = floor((p.y - y_offset) * scale * 0.4);
	
	// More varied density check
	float row_seed = row + layer * 50.0 + column * 0.1;
	float row_hash = hash(vec2(column, row_seed));
	float density_threshold = rain_density * mix(0.7, 1.3, hash(vec2(row_seed, col_seed)));
	
	if (row_hash > density_threshold) return 0.0;
	
	vec2 cell_uv = fract(vec2(p.x * scale, (p.y - y_offset) * scale * 0.4));
	
	// More random drop position within cell
	float drop_x = 0.5 + x_jitter + (hash(vec2(column, row + layer * 33.3)) - 0.5) * 0.3;
	vec2 drop_center = vec2(clamp(drop_x, 0.15, 0.85), 0.5);
	
	float dx = abs(cell_uv.x - drop_center.x);
	float dy = cell_uv.y - drop_center.y;
	
	// Elongated raindrop shape with size variation
	float size_var = mix(0.7, 1.3, hash(vec2(column + row, layer)));
	float drop = smoothstep(thickness * size_var, 0.0, dx) * 
				 smoothstep(-length_factor * size_var, 0.0, dy) * 
				 smoothstep(length_factor * 0.3 * size_var, 0.0, -dy);
	
	// Brightness variation
	float brightness = mix(0.5, 1.0, hash(vec2(column * 1.7, row * 2.3)));
	
	return drop * brightness * mix(0.4, 1.0, 1.0 - layer);
}

// Splash effect when drops hit the ground (world-space)
float splashes(vec2 world_uv, float t) {
	float splash = 0.0;
	
	// Grid-based splash positions in world space
	float grid_size = 0.15;
	vec2 grid_cell = floor(world_uv / grid_size);
	
	// Check nearby cells for splashes
	for (float gx = -1.0; gx <= 1.0; gx++) {
		for (float gy = -1.0; gy <= 1.0; gy++) {
			vec2 cell = grid_cell + vec2(gx, gy);
			
			// Random position within cell
			vec2 cell_hash = hash22(cell * 127.1);
			vec2 splash_world_pos = (cell + cell_hash) * grid_size;
			
			// Time offset per splash (so they don't all sync)
			float time_offset = hash(cell) * 6.28;
			float splash_period = mix(0.8, 1.5, hash(cell * 1.7));
			float splash_time = fract(t / splash_period + time_offset);
			
			vec2 delta = world_uv - splash_world_pos;
			float dist = length(delta * vec2(1.0, 1.3));
			
			// Expanding ring
			float ring_radius = splash_time * 0.06;
			float ring = smoothstep(ring_radius + 0.012, ring_radius + 0.004, dist) *
						 smoothstep(ring_radius - 0.008, ring_radius, dist);
			
			// Fade out
			float fade = (1.0 - splash_time) * (1.0 - splash_time);
			
			// Center splash
			float inner = smoothstep(0.015, 0.0, dist) * (1.0 - splash_time * 2.5);
			inner = max(inner, 0.0);
			
			// Vary intensity per splash
			float intensity = mix(0.4, 1.0, hash(cell * 2.3));
			
			splash += (ring * 0.6 + inner) * fade * intensity;
		}
	}
	
	return splash * splash_intensity;
}

// Lightning bolts across the sky
float lightning(vec2 uv, float t) {
	float lightning_effect = 0.0;
	
	// Multiple lightning bolts
	for (float i = 0.0; i < 3.0; i++) {
		// Random bolt position and timing
		float bolt_x = hash(vec2(i * 41.23, 0.0));
		float bolt_seed = i * 73.156;
		
		// Lightning strike pattern
		float strike_period = mix(3.0, 8.0, hash(vec2(i, 1.0)));
		float strike_time = fract(t / strike_period + hash(vec2(i, 2.0)));
		
		// Quick flash at the start
		float flash_duration = 0.15;
		float is_flashing = step(strike_time, flash_duration);
		
		// Create branching effect
		vec2 bolt_start = vec2(bolt_x, 1.0);
		vec2 delta = uv - bolt_start;
		
		// Main bolt line (vertical with slight jitter)
		float jitter = sin(uv.y * 20.0 + bolt_seed) * 0.03;
		float bolt_width = 0.008;
		float main_bolt = smoothstep(bolt_width, 0.0, abs(delta.x - jitter)) * 
						  step(0.0, delta.y) * step(delta.y, 0.6);
		
		// Secondary branches
		float branch1 = smoothstep(0.006, 0.0, abs(delta.x - jitter - 0.05)) * 
					    step(0.2, delta.y) * step(delta.y, 0.5);
		float branch2 = smoothstep(0.006, 0.0, abs(delta.x - jitter + 0.04)) * 
					    step(0.3, delta.y) * step(delta.y, 0.55);
		
		// Glow around bolt
		float glow = smoothstep(0.08, 0.0, abs(delta.x - jitter)) * 
					 step(0.0, delta.y) * step(delta.y, 0.6) * 0.3;
		
		// Fade in and out
		float fade = is_flashing * (1.0 - smoothstep(0.0, flash_duration, strike_time));
		
		lightning_effect += (main_bolt + branch1 * 0.6 + branch2 * 0.6 + glow) * fade;
	}
	
	return lightning_effect * lightning_intensity;
}

// Small droplets accumulated on screen
float droplets(vec2 uv, float t) {
	float drops = 0.0;
	
	for (float i = 0.0; i < 15.0; i++) {
		vec2 pos = hash22(vec2(i * 57.12, i * 113.45));
		float size = mix(0.008, 0.02, hash(vec2(i, 10.0)));
		
		// Subtle movement
		pos.x += sin(t * 0.2 + i * 0.5) * 0.01;
		pos.y += fract(t * 0.02 + hash(vec2(i, 5.0))) * 0.1;
		pos = fract(pos);
		
		float dist = length(uv - pos);
		float drop = smoothstep(size, size * 0.3, dist);
		
		// Lens distortion effect (brighter center)
		float highlight = smoothstep(size * 0.8, size * 0.2, dist) * 0.5;
		
		drops += (drop * 0.3 + highlight);
	}
	
	return drops * drip_intensity * 0.5;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	
	// Convert screen UV to world coordinates
	vec2 world_uv_offset = vec2(world_offset.x, -world_offset.y) * world_scale;
	vec2 world_uv = uv + world_uv_offset;
	
	// Calcular coordenadas de mundo para cada capa (parallax)
	vec2 world_uv_front = uv + vec2(world_offset.x, world_offset.y) * world_scale * 1.0;
	vec2 world_uv_mid = uv + vec2(world_offset.x, world_offset.y) * world_scale * 0.7;
	vec2 world_uv_back = uv + vec2(world_offset.x, world_offset.y) * world_scale * 0.4;
	
	// Separar las capas de lluvia para aplicar colores individuales
	// Capas más cercanas reaccionan más al movimiento del jugador (parallax)
	float rain_front = raindrops(uv, world_uv_front, t, 0.0, 1.0) * 1.0;
	float rain_mid = raindrops(uv, world_uv_mid, t, 0.5, 0.6) * 0.6;
	float rain_back = raindrops(uv, world_uv_back, t, 1.0, 0.3) * 0.3;
	
	// Calcular otros efectos
	float splash = splashes(world_uv_front, t);
	float light = lightning(uv, t);
	float drops = droplets(uv, t);
	
	// Combinar todas las intensidades para el alpha
	float total = rain_front + rain_mid + rain_back + splash + light + drops;
	
	// Aplicar colores configurables a cada elemento
	vec3 final_color = vec3(0.0);
	final_color += rain_color_front.rgb * rain_front;   // ROJO - Gotas frontales
	final_color += rain_color_mid.rgb * rain_mid;       // VERDE - Gotas medias
	final_color += rain_color_back.rgb * rain_back;     // AZUL - Gotas traseras
	final_color += splash_color.rgb * splash;           // AMARILLO - Salpicaduras
	final_color += lightning_color.rgb * light;         // VIOLETA - Relámpagos
	final_color += droplet_color.rgb * drops;           // NARANJA - Gotitas
	
	// Lightning flash effect
	float flash = lightning_flash * (0.5 + 0.5 * sin(TIME * 30.0));
	final_color += vec3(flash * 0.3);
	total += flash * 0.1;
	
	// Final alpha combinando todos los alphas
	float alpha = clamp(
		rain_front * rain_color_front.a +
		rain_mid * rain_color_mid.a +
		rain_back * rain_color_back.a +
		splash * splash_color.a +
		light * lightning_color.a +
		drops * droplet_color.a,
		0.0, 1.0
	);
	
	// Add subtle vignette to rain (more rain visible at edges)
	float vignette = 1.0 - length((uv - 0.5) * 0.5);
	alpha *= mix(0.8, 1.0, vignette);
	
	COLOR = vec4(final_color, alpha);
}
