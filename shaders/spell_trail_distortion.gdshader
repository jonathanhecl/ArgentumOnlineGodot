shader_type canvas_item;
render_mode blend_mix;

// Lee la pantalla detras de la particula para distorsionar/corromper el fondo
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

// Fuerza de la distorsion en direccion de flecha hacia el objetivo (UV-space: 0.01 ≈ ~10-20 px)
uniform float distortion_strength : hint_range(0.0, 0.15) = 0.04;
// Direccion normalizada del vuelo (caster -> target) en screen-space
uniform vec2 flight_dir = vec2(1.0, 0.0);

// Cuanto del color del hechizo se tinta sobre el fondo distorsionado
uniform float tint_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    // La textura radial define la mascara suave del humo (alpha al centro, 0 en el borde)
    vec4 tex = texture(TEXTURE, UV);
    float mask = tex.a * COLOR.a;

    // Empuje direccional: toda la particula empuja el fondo como flecha hacia el objetivo
    vec2 offset = flight_dir * distortion_strength * mask;

    // Muestreamos el fondo desplazado -> efecto de corrupcion/refraccion
    vec3 bg = texture(screen_tex, SCREEN_UV + offset).rgb;

    // Tintamos con el color del hechizo (azul -> rojo proveniente del process material)
    vec3 tinted = mix(bg, COLOR.rgb, tint_amount * mask);

    COLOR.rgb = tinted;
    COLOR.a = mask;
}
