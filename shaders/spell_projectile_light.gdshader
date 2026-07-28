shader_type canvas_item;
render_mode blend_add;

// Luz sutil en forma de flecha que apunta hacia el objetivo del hechizo.
// UV.x = 0 en la cola (detras del proyectil), UV.x = 1 en la punta (el proyectil).
uniform float intensity : hint_range(0.0, 2.0) = 0.6;
// UV.x a partir del cual la cola es visible. La cola arranca en la linea del
// lanzador y crece hacia atras a medida que el proyectil se aleja.
// 0.8 = sin cola (recien lanzado, pegada al orbe), 0.0 = cola completa.
uniform float tail_clip_x : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    float x = UV.x;                    // 0 = cola, 1 = punta (orbe)
    float y = abs(UV.y - 0.5) * 2.0;   // 0 = centro, 1 = borde lateral

    // Cola: fina atras, se ensancha suavemente hasta fundirse con la cabeza
    float w = mix(0.05, 0.35, smoothstep(0.0, 0.8, x));
    // tail_mask: transicion suave en tail_clip_x (sin borde duro en el recorte)
    float tail_mask = smoothstep(tail_clip_x - 0.03, tail_clip_x + 0.03, x);
    float tail = smoothstep(w, 0.0, y) * tail_mask * 0.45;

    // Cabeza: glow circular alrededor del orbe (aspecto corregido 192/72)
    vec2 head_p = vec2((x - 0.8) * 2.67, y);
    float head = smoothstep(0.4, 0.1, length(head_p));

    float alpha = clamp(tail + head, 0.0, 1.0) * intensity;
    COLOR = vec4(1.0, 1.0, 1.0, alpha);
}
