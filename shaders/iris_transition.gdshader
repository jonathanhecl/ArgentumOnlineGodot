shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float smooth_size : hint_range(0.0, 1.0) = 0.1;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV;
	
	// Centrar UV y ajustar aspect ratio para hacer un círculo perfecto
	// (Asumiendo que el canvas no es perfectamente cuadrado)
	// Como no tenemos el aspect ratio aquí, hacemos un aproximado circular
	vec2 center = vec2(0.5, 0.5);
	
	// Distancia al centro
	float dist = distance(uv, center);
	
	// Cálculo del radio basado en el progreso
	// progress 0.0 = círculo completamente abierto (radio grande, dist > radius nunca o casi nunca)
	// progress 1.0 = círculo completamente cerrado (radio 0)
	
	// Multiplicamos por 0.8 para cubrir las esquinas al estar abierto
	float radius = (1.0 - progress) * 0.8;
	
	// Borde suave
	float alpha = smoothstep(radius, radius + smooth_size, dist);
	
	COLOR = vec4(color.rgb, alpha * color.a);
}