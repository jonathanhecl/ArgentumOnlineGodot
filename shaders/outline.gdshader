shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.5, 1.0, 0.7); // Azul con transparencia
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    vec2 ps = TEXTURE_PIXEL_SIZE;
    
    float max_alpha = 0.0;
    
    // Verificar los píxeles vecinos
    for(float x = -outline_width; x <= outline_width; x++) {
        for(float y = -outline_width; y <= outline_width; y++) {
            if (x != 0.0 || y != 0.0) {
                max_alpha = max(max_alpha, texture(TEXTURE, UV + vec2(ps.x * x, ps.y * y)).a);
            }
        }
    }
    
    // Si el píxel actual es transparente pero hay un píxel opaco cerca, dibujar el borde
    if (col.a < 0.5 && max_alpha > 0.5) {
        COLOR = outline_color;
    } else {
        COLOR = col;
    }
}
