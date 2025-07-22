extends RefCounted
class_name ShowGuildFundationFormCommand

# Señal que se emite cuando se envía el formulario
signal form_submitted(name: String, url: String)

# Referencia al nodo padre donde se agregará la ventana
var parent_node: Node

# Constructor
func _init(p_parent_node: Node = null):
	parent_node = p_parent_node

# Método estático para crear una instancia desde un StreamPeerBuffer
static func from_buffer(_stream: StreamPeerBuffer, p_parent_node: Node) -> ShowGuildFundationFormCommand:
	var instance = ShowGuildFundationFormCommand.new(p_parent_node)
	return instance

# Método para manejar la lógica cuando se recibe este paquete
func handle() -> void:
	print("[DEBUG] ShowGuildFundationFormCommand.handle() - Iniciando")
	
	# Verificar que tenemos un nodo padre válido
	if not parent_node:
		push_error("No se pudo mostrar el formulario de fundación: nodo padre es null")
		return
		
	if not is_instance_valid(parent_node):
		push_error("No se pudo mostrar el formulario de fundación: nodo padre no es una instancia válida")
		return
	
	var node_name = "(sin nombre)"
	if parent_node.has_method("get_name"):
		node_name = parent_node.name
	print("[DEBUG] Nodo padre válido: ", node_name)
	
	# Mostrar la ventana del formulario de fundación
	_show_foundation_window()
	print("[DEBUG] Ventana de fundación mostrada")

# Muestra la ventana del formulario de fundación
func _show_foundation_window() -> void:
	print("[DEBUG] _show_foundation_window() - Cargando escena...")
	
	# Cargar la escena de la ventana de fundación
	var foundation_window_scene = preload("res://ui/hub/guild_foundation_window.tscn")
	
	if not foundation_window_scene:
		push_error("No se pudo cargar la escena guild_foundation_window.tscn")
		return
	
	var foundation_window = foundation_window_scene.instantiate()
	
	if not foundation_window:
		push_error("No se pudo instanciar la ventana de fundación")
		return
	
	print("[DEBUG] Ventana instanciada: ", foundation_window)
	
	# Verificar y conectar las señales
	var next_connected = foundation_window.has_signal("next_pressed")
	var closed_connected = foundation_window.has_signal("window_closed")
	
	print("[DEBUG] Señales disponibles - next_pressed: ", next_connected, ", window_closed: ", closed_connected)
	
	if next_connected:
		foundation_window.connect("next_pressed", Callable(self, "_on_next_pressed"))
		print("[DEBUG] Señal next_pressed conectada")
	
	if closed_connected:
		foundation_window.connect("window_closed", Callable(self, "_on_window_closed"))
		print("[DEBUG] Señal window_closed conectada")
	
	# Agregar la ventana al nodo padre
	print("[DEBUG] Agregando ventana al nodo padre...")
	parent_node.add_child(foundation_window)
	print("[DEBUG] Ventana agregada al nodo padre")
	
	# Centrar la ventana en la pantalla
	var viewport = parent_node.get_viewport()
	if viewport:
		var viewport_size = viewport.get_visible_rect().size
		var window_size = Vector2(400, 300)  # Tamaño fijo para asegurar que se vea bien
		
		if foundation_window.has_method("get_size"):
			window_size = foundation_window.size
		
		print("[DEBUG] Centrando ventana. Tamaño: ", window_size, ", Viewport: ", viewport_size)
		foundation_window.position = (viewport_size - window_size) / 2
		
		# Llamar a show_window() si existe el método
		if foundation_window.has_method("show_window"):
			foundation_window.show_window()
		else:
			print("[DEBUG] La ventana no tiene el método show_window()")
	else:
		print("[DEBUG] No se pudo obtener el viewport")

# Manejador para cuando se presiona el botón Siguiente
func _on_next_pressed(name: String, url: String) -> void:
	# Emitir señal con los datos del formulario
	form_submitted.emit(name, url)

# Manejador para cuando se cierra la ventana
func _on_window_closed() -> void:
	# No es necesario hacer nada aquí, la ventana se encarga de liberarse a sí misma
	pass
