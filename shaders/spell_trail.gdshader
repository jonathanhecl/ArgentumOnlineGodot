shader_type particles;

uniform vec4 start_color : source_color = vec4(0.0, 0.7, 1.0, 1.0);   // Azul cian brillante - inicio del hechizo
uniform vec4 end_color : source_color = vec4(1.0, 0.0, 0.15, 1.0);   // Rojo fuego brillante - vapor final
uniform float color_intensity : hint_range(1.0, 5.0) = 2.5;          // Multiplicador de brillo/emisión
uniform float initial_scale = 0.75;
uniform float random_spread = 8.0;

// High-fidelity hash function for random seeds
uint hash(uint x) {
    x = ((x >> 16u) ^ x) * 0x45d9f3bU;
    x = ((x >> 16u) ^ x) * 0x45d9f3bU;
    x = (x >> 16u) ^ x;
    return x;
}

// Pseudo-random generator from seed
float rand_from_seed(inout uint seed) {
    int k;
    int s = int(seed);
    if (s == 0) s = 305175781;
    k = s / 127773;
    s = 16807 * (s - k * 127773) - k * 2836;
    if (s < 0) s += 2147483647;
    seed = uint(s);
    return float(seed) / 2147483647.0;
}

void start() {
    ACTIVE = true;
    
    // Seed initialization using unique index and number keys
    uint alt_seed = hash(NUMBER + uint(INDEX) + RANDOM_SEED);
    
    // 1. Position Spread: soft offset around center to give the comet tail a thick base
    float offset_x = (rand_from_seed(alt_seed) - 0.5) * random_spread;
    float offset_y = (rand_from_seed(alt_seed) - 0.5) * random_spread;
    TRANSFORM[3].x += offset_x;
    TRANSFORM[3].y += offset_y;
    
    // 2. Velocity: gentle outward dispersion/float
    float vel_x = (rand_from_seed(alt_seed) - 0.5) * 15.0;
    float vel_y = (rand_from_seed(alt_seed) - 0.5) * 15.0;
    VELOCITY = vec3(vel_x, vel_y, 0.0);
    
    // 3. Color inicial (azul)
    COLOR = start_color;
    
    // Inicializar el acumulador de edad de la particula
    CUSTOM.y = 0.0;
    
    // 4. Initial Scale: slight randomization around initial_scale
    float final_scale = initial_scale * mix(0.8, 1.2, rand_from_seed(alt_seed));
    
    TRANSFORM[0].x = final_scale;
    TRANSFORM[1].y = final_scale;
    TRANSFORM[2].z = final_scale;
}

void process() {
    // Acumular la edad de la particula (Godot no la provee automaticamente en el process shader)
    CUSTOM.y += DELTA;
    
    float ratio = 0.0;
    if (LIFETIME > 0.0) {
        ratio = clamp(CUSTOM.y / LIFETIME, 0.0, 1.0);
    }
    
    // 1. Color Transition: de azul (inicio) a rojo (vapor final)
    // Usamos smoothstep para evitar la fea zona gris del medio y mantener los colores puros mas tiempo
    float transition = smoothstep(0.35, 0.65, ratio);
    vec3 current_color = mix(start_color.rgb, end_color.rgb, transition);
    
    // Multiplicamos por intensidad para que brille como magia pura, no como humo apagado
    COLOR.rgb = current_color * color_intensity;
    
    // 2. Fade Out: starts fully visible and fades to 0 over lifetime
    float start_alpha = start_color.a;
    float end_alpha = end_color.a * 0.5;  // El vapor final es más tenue
    COLOR.a = mix(start_alpha, end_alpha, ratio) * (1.0 - ratio * 0.8);
    
    // 3. Comet Tail Scaling: starts at full initial scale and shrinks down to 0
    float current_scale = initial_scale * (1.0 - ratio * 0.95);
    
    // Normalize basis vectors to prevent exponential scaling and set absolute scale
    TRANSFORM[0].xyz = normalize(TRANSFORM[0].xyz) * current_scale;
    TRANSFORM[1].xyz = normalize(TRANSFORM[1].xyz) * current_scale;
    TRANSFORM[2].xyz = normalize(TRANSFORM[2].xyz) * current_scale;
}
