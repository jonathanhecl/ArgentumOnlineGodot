extends RefCounted
class_name ShowGuildAlign

# Señal que se emite cuando se selecciona una alineación
signal alignment_selected(alignment_type: int)

# Referencia al nodo padre donde se agregará la ventana de alineación
var parent_node: Node

# Constructor
func _init(p_parent_node: Node = null):
	parent_node = p_parent_node

# Método estático para crear una instancia desde un StreamPeerBuffer
static func from_buffer(_stream: StreamPeerBuffer, p_parent_node: Node) -> ShowGuildAlign:
	var instance = ShowGuildAlign.new(p_parent_node)
	return instance

# Método para manejar la lógica cuando se recibe este paquete
func handle() -> void:
	# Verificar que tenemos un nodo padre válido
	if not parent_node or not is_instance_valid(parent_node):
		push_error("No se pudo mostrar la ventana de alineación: nodo padre no válido")
		return
		
	# Mostrar la ventana de selección de alineación
	_show_alignment_window()

# Muestra la ventana de selección de alineación
func _show_alignment_window() -> void:
	# Cargar la escena de la ventana de alineación
	var alignment_window_scene = preload("res://ui/hub/guild_alignment_window.tscn")
	var alignment_window = alignment_window_scene.instantiate()
	
	# Conectar la señal de selección de alineación
	alignment_window.connect("alignment_selected", Callable(self, "_on_alignment_selected"))
	
	# Agregar la ventana al nodo padre
	parent_node.add_child(alignment_window)
	
	# Centrar la ventana en la pantalla
	var viewport = parent_node.get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		var window_size = Vector2(alignment_window.size)
		alignment_window.position = (viewport_size - window_size) / 2
	else:
		# Fallback: Centrar manualmente si no se puede obtener el viewport
		var window_size = Vector2(alignment_window.size)
		alignment_window.position = (Vector2(800, 600) - window_size) / 2

# Manejador para cuando se selecciona una alineación
func _on_alignment_selected(alignment_type: int) -> void:
	# Convertir el tipo de alineación a string para el log
	var alignment_name = ""
	match alignment_type:
		0: alignment_name = "Real"
		1: alignment_name = "Caos"
		2: alignment_name = "Neutral"
		4: alignment_name = "Legal"
		5: alignment_name = "Criminal"
		_: 
			push_error("Alineación de clan no válida: " + str(alignment_type))
			return
	
	# Registrar la acción en los logs del cliente para depuración
	print("[DEBUG] Alineación de clan seleccionada: ", alignment_name, " (tipo: ", alignment_type, ")")
	
	# Enviar la alineación seleccionada al servidor
	print("[DEBUG] Enviando alineación al servidor...")
	var protocol = load("res://engine/autoload/game_protocol.gd")
	if protocol:
		protocol.WriteGuildFundation(alignment_type)
	else:
		push_error("No se pudo cargar el módulo de protocolo del juego")
	
	# La ventana ya se cierra sola cuando se selecciona una alineación
	# gracias a la señal alignment_selected en guild_alignment_window.gd
	
	# Emitir señal con la alineación seleccionada
	emit_signal("alignment_selected", alignment_type)
	print("[DEBUG] Señal alignment_selected emitida con tipo: ", alignment_type)
