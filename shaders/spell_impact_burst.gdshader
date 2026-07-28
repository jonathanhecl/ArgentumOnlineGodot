shader_type canvas_item;
render_mode blend_add;

// Explosion de luz al impactar el hechizo.
// Anillo de rayos que se expande desde el punto de impacto, sesgado hacia
// la direccion del vuelo (+X local, rotado por el nodo).
uniform float progress : hint_range(0.0, 1.0) = 0.0; // 0 = explosion, 1 = disipada
uniform float intensity : hint_range(0.0, 3.0) = 1.2;
uniform float ray_count = 7.0;

void fragment() {
    vec2 p = vec2((UV.x - 0.5) * 2.0, (UV.y - 0.5) * 2.0); // -1..1, centro en el impacto
    float dist = length(p);
    float ang = atan(p.y, p.x);

    // Rayos angulares alrededor del impacto
    float rays = 0.5 + 0.5 * sin(ang * ray_count + dist * 4.0);

    // Anillo que se expande con el progreso
    float ring = smoothstep(progress + 0.3, progress, dist)
               * smoothstep(progress - 0.4, progress - 0.05, dist);

    // Flash central inicial que muere rapido
    float flash = smoothstep(0.45, 0.0, dist) * (1.0 - smoothstep(0.0, 0.35, progress));

    // Sesgo direccional: los rayos dominan hacia donde venia el hechizo (+X)
    float dir_bias = 0.25 + 1.75 * smoothstep(-1.0, 1.0, p.x);

    float fade = 1.0 - progress;

    // Mascara de borde: desaparecer antes de que se vean los bordes cuadrados de la textura
    float edge = smoothstep(0.95, 0.55, dist);

    float alpha = clamp(ring * (0.35 + 0.65 * rays) * dir_bias + flash, 0.0, 1.5) * fade * edge * intensity;
    COLOR = vec4(1.0, 1.0, 1.0, alpha);
}
