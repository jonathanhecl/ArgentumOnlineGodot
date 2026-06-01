shader_type canvas_item;

// Lee la pantalla detras para el efecto de surco/refraccion
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

// Amplitud del surco (desplazamiento perpendicular). Aumentado para ser visible.
uniform float amplitude : hint_range(0.0, 0.06) = 0.018;

// Cuantas ondas caben en el largo del surco
uniform float frequency : hint_range(1.0, 20.0) = 6.0;

// Velocidad de la animacion de las ondas en el surco
uniform float speed : hint_range(0.0, 20.0) = 5.0;

// Offset de tiempo individual por proyectil
uniform float time_offset = 0.0;

// Angulo de vuelo en radianes (de lanzador a objetivo)
uniform float flight_angle = 0.0;

// Disipacion progresiva del surco (0 = recien impacto, 1 = desaparecido)
uniform float dissipation : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // UV.x = eje a lo largo del surco (0=inicio, 1=punta del proyectil)
    // UV.y = eje perpendicular (0.5=centro del surco)
    float along = UV.x;           // posicion a lo largo de la trayectoria
    float perp  = UV.y - 0.5;     // desviacion lateral (-0.5..0.5)

    // Mascara de ancho del surco: solo afecta una franja delgada central
    float width_mask = 1.0 - smoothstep(0.0, 0.45, abs(perp));

    // Onda sinusoidal que corre a lo largo del surco (como una ola avanzando)
    float wave = sin(along * frequency * 6.2831 - (TIME + time_offset) * speed);

    // Mascara de fade en los extremos: suave en cabeza y cola
    float tail_fade = smoothstep(0.0, 0.12, along);
    float head_fade = 1.0 - smoothstep(0.82, 1.0, along);
    float fade = tail_fade * head_fade;

    // Disipacion progresiva: la onda se desvanece suavemente
    float dissipate = 1.0 - smoothstep(0.0, 1.0, dissipation);

    // Desplazamiento perpendicular a la trayectoria en espacio de pantalla
    // Rotamos el desplazamiento segun flight_angle
    float disp = wave * amplitude * width_mask * fade * dissipate;
    vec2 perp_dir = vec2(-sin(flight_angle), cos(flight_angle));
    vec2 offset = perp_dir * disp;

    vec3 bg = texture(screen_tex, SCREEN_UV + offset).rgb;

    float alpha = width_mask * fade * 0.92 * dissipate;
    COLOR = vec4(bg, alpha);
}
