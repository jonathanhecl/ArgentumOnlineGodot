shader_type particles;

uniform vec4 trail_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float initial_scale = 0.75;
uniform float random_spread = 8.0;

// High-fidelity hash function for random seeds
uint hash(uint x) {
    x = ((x >> 16) ^ x) * 0x45d9f3bU;
    x = ((x >> 16) ^ x) * 0x45d9f3bU;
    x = (x >> 16) ^ x;
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
    
    // 3. Color
    COLOR = trail_color;
    
    // 4. Initial Scale: slight randomization around initial_scale
    float final_scale = initial_scale * mix(0.8, 1.2, rand_from_seed(alt_seed));
    
    TRANSFORM[0].x = final_scale;
    TRANSFORM[1].y = final_scale;
    TRANSFORM[2].z = final_scale;
}

void process() {
    float ratio = 0.0;
    if (LIFETIME > 0.0) {
        ratio = CUSTOM.y / LIFETIME;
    }
    
    // 1. Fade Out: starts fully visible and fades to 0 over lifetime
    COLOR.a = (1.0 - ratio) * trail_color.a;
    
    // 2. Comet Tail Scaling: starts at full initial scale and shrinks down to 0
    float current_scale = initial_scale * (1.0 - ratio * 0.95);
    
    // Normalize basis vectors to prevent exponential scaling and set absolute scale
    TRANSFORM[0].xyz = normalize(TRANSFORM[0].xyz) * current_scale;
    TRANSFORM[1].xyz = normalize(TRANSFORM[1].xyz) * current_scale;
    TRANSFORM[2].xyz = normalize(TRANSFORM[2].xyz) * current_scale;
}
