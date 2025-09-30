extends RefCounted
class_name ShowGuildFundationForm

# Señal que se emite cuando se envía el formulario
signal form_submitted(clan_name: String, clan_abbreviation: String, url: String, description: String)

# Referencia al nodo padre donde se agregará la ventana
var parent_node: Node

# Constructor
func _init(p_parent_node: Node = null):
	parent_node = p_parent_node

# Método estático para crear una instancia desde un StreamPeerBuffer
static func from_buffer(_stream: StreamPeerBuffer, p_parent_node: Node) -> ShowGuildFundationForm:
	var instance = ShowGuildFundationForm.new(p_parent_node)
	return instance

# Método para manejar la lógica cuando se recibe este paquete
func handle() -> void:
	# Mostrar la ventana de fundación de clan
	if parent_node and parent_node.has_method("show_guild_foundation_window"):
		parent_node.show_guild_foundation_window()
	else:
		push_error("No se pudo mostrar la ventana de fundación de clan. Nodo padre inválido o método no disponible.")
