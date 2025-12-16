extends Node

# Precargar escenas necesarias
const CharacterSelectionScene = preload("res://screens/character_selection_screen.tscn")

enum State {
	None,
	LoginAccount,
	RegisterAccount
}

@export var _loginPanel: LoginPanel

var _state: State

func _ready() -> void:
	ClientInterface.connected.connect(_OnConnected)
	ClientInterface.disconnected.connect(_OnDisconnected)
	ClientInterface.connection_timeout.connect(_OnConnectionTimeout)
	
	# Conectar señales del ProtocolHandler para eventos de login
	ProtocolHandler.error_msg_received.connect(_on_error_msg)
	ProtocolHandler.account_logged.connect(_on_account_logged)
	ProtocolHandler.show_message_box.connect(_on_show_message_box)
	ProtocolHandler.logged_in.connect(_on_logged_in)
	
	print("🔍 LoginScreen._ready: Tamaño del LoginPanel: ", _loginPanel.size)
	print("🔍 LoginScreen._ready: Posición del LoginPanel: ", _loginPanel.position)
	print("🔍 LoginScreen._ready: Visible del LoginPanel: ", _loginPanel.visible)
	
	# Verificar todos los nodos en el root
	print("🔍 Nodos en root:")
	for i in range(get_tree().root.get_child_count()):
		var child = get_tree().root.get_child(i)
		print("  [", i, "] ", child.name, " (", child.get_class(), ")")
		if child is CanvasLayer:
			print("    -> CanvasLayer layer: ", child.layer)
	
	# Verificar el Main container
	var main_node = get_tree().root.get_node("Main")
	if main_node:
		var main_container = main_node.get_node("VBoxContainer")
		print("🔍 LoginScreen._ready: MainContainer visible: ", main_container.visible)
		print("🔍 LoginScreen._ready: MainContainer size: ", main_container.size)
	
	# Forzar layer alto para el CanvasLayer del login
	var canvas_layer = _loginPanel.get_parent()
	if canvas_layer:
		print("🔍 LoginScreen._ready: CanvasLayer visible: ", canvas_layer.visible)
		print("🔍 LoginScreen._ready: CanvasLayer is_inside_tree: ", canvas_layer.is_inside_tree())
		print("🔍 LoginScreen._ready: CanvasLayer layer ANTES: ", canvas_layer.layer)
		canvas_layer.layer = 100
		print("🔍 LoginScreen._ready: CanvasLayer layer DESPUÉS: ", canvas_layer.layer)
		canvas_layer.visible = true
		print("🔍 LoginScreen._ready: CanvasLayer visible forzado a: ", canvas_layer.visible)
	
	# Forzar modulate a blanco para asegurar visibilidad
	_loginPanel.modulate = Color.WHITE
	print("🔍 LoginScreen._ready: Modulate del LoginPanel: ", _loginPanel.modulate)
	
	_loginPanel.error.connect(func(message):
		Utils.ShowAlertDialog("Login", message, self))

func _exit_tree() -> void:
	# Desconectar señales del ProtocolHandler al salir
	if ProtocolHandler.error_msg_received.is_connected(_on_error_msg):
		ProtocolHandler.error_msg_received.disconnect(_on_error_msg)
	if ProtocolHandler.account_logged.is_connected(_on_account_logged):
		ProtocolHandler.account_logged.disconnect(_on_account_logged)
	if ProtocolHandler.show_message_box.is_connected(_on_show_message_box):
		ProtocolHandler.show_message_box.disconnect(_on_show_message_box)
	if ProtocolHandler.logged_in.is_connected(_on_logged_in):
		ProtocolHandler.logged_in.disconnect(_on_logged_in)

func _OnConnected() -> void:
	Security.reset_redundance()
	
	if _state == State.RegisterAccount:
		_show_register_account_dialog()
	elif _state == State.LoginAccount:
		GameProtocol.WriteLoginExistingAccount(_loginPanel.GetUsername(), _loginPanel.GetPassword())
		_Flush()
	
func _OnDisconnected() -> void:
	_state = State.None
	_loginPanel.EnableAuthControls()

func _OnConnectionTimeout() -> void:
	_state = State.None
	_loginPanel.EnableAuthControls()
	Utils.ShowAlertDialog("Error de Conexión", "No se pudo conectar al servidor.\nEl intento de conexión ha excedido el tiempo límite.", self)
	
func _GetEnpoint() -> Dictionary:
	return {
		"ip": %Ip.text,
		"port": int(%Port.value)
	}

#region Protocol Signal Handlers

func _on_error_msg(message: String) -> void:
	Utils.ShowAlertDialog("Server", message, self)
	ClientInterface.DisconnectFromHost()

func _on_account_logged(account_name: String, _account_hash: String, characters: Array) -> void:
	# Cambiar a pantalla de selección de personajes
	var char_selection_screen = CharacterSelectionScene.instantiate()
	char_selection_screen.set_account_data(account_name, characters)
	
	# Conectar señales
	char_selection_screen.character_selected.connect(_on_character_selected)
	char_selection_screen.create_character_requested.connect(_on_create_character_requested)
	char_selection_screen.logout_requested.connect(_on_logout_requested)
	
	ScreenController.SwitchScreen(char_selection_screen)

func _on_show_message_box(message: String) -> void:
	var root = get_tree().root
	Utils.ShowAlertDialog("Servidor", message, root)

func _on_logged_in() -> void:
	var screen = load("uid://b2dyxo3826bub").instantiate() as GameScreen
	ScreenController.SwitchScreen(screen)

#endregion
		
func _OnLoginPanelSubmit() -> void:
	_ConnectToHost(State.LoginAccount)
		
func _OnLoginPanelRegister() -> void:
	_ConnectToHost(State.RegisterAccount)
		
func _ConnectToHost(state: State) -> void:
	#if ClientInterface.IsConnected():
	#	ClientInterface.DisconnectFromHost()
	_state = state
	_loginPanel.DisableAuthControls()
	
	var endpoint = _GetEnpoint()
	ClientInterface.ConnectToHost(endpoint.ip, endpoint.port)

func _Flush() -> void:
	ClientInterface.Send(GameProtocol.Flush())

func _show_register_account_dialog() -> void:
	"""Mostrar ventana para ingresar email y contraseña de la nueva cuenta"""
	var dialog = AcceptDialog.new()
	dialog.title = "Registrar nueva cuenta"
	dialog.min_size = Vector2(420, 0)
	
	var content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(380, 0)
	content.add_theme_constant_override("separation", 10)

	var email_label = Label.new()
	email_label.text = "Email de la cuenta"
	content.add_child(email_label)

	var email_input = LineEdit.new()
	email_input.placeholder_text = "correo@dominio.com"
	email_input.text = _loginPanel.GetUsername()
	content.add_child(email_input)

	var password_label = Label.new()
	password_label.text = "Contraseña"
	content.add_child(password_label)

	var password_input = LineEdit.new()
	password_input.secret = true
	password_input.placeholder_text = "Contraseña (3 a 15 caracteres)"
	password_input.text = _loginPanel.GetPassword()
	content.add_child(password_input)

	dialog.add_child(content)

	dialog.confirmed.connect(func():
		var email = email_input.text.strip_edges()
		var password = password_input.text
		if not _is_valid_email(email):
			Utils.ShowAlertDialog("Registro", "Ingresa un email válido para la cuenta.", self)
			dialog.popup_centered()
			return
		
		var password_error = _validate_account_password(password)
		if password_error != "":
			Utils.ShowAlertDialog("Registro", password_error, self)
			dialog.popup_centered()
			return
		
		_loginPanel.SetCredentials(email, password)
		GameProtocol.WriteLoginNewAccount(email, password)
		_Flush()
	)

	add_child(dialog)
	dialog.popup_centered()

func _on_character_selected(character_name: String) -> void:
	"""Cuando se selecciona un personaje para jugar"""
	print("Jugando con personaje: ", character_name)
	
	# Enviar al servidor que queremos jugar con este personaje
	GameProtocol.WriteLoginExistingCharacter(character_name, _loginPanel.GetPassword())
	_Flush()
	
	# Esperar respuesta del servidor con Logged

func _on_create_character_requested() -> void:
	"""Cuando se solicita crear un nuevo personaje"""
	print("Crear nuevo personaje solicitado")
	
	# Cargar pantalla de creación de personaje
	var screen = load("uid://bp35uafwebjdb").instantiate()
	ScreenController.SwitchScreen(screen)

func _on_logout_requested() -> void:
	"""Cuando se solicita cerrar sesión"""
	print("Cerrar sesión solicitado")
	
	# Desconectar del servidor
	ClientInterface.DisconnectFromHost()
	
	# Volver a pantalla de login
	var login_screen = load("res://screens/login_screen.tscn").instantiate()
	ScreenController.SwitchScreen(login_screen)


func _is_valid_email(email: String) -> bool:
	if email.is_empty():
		return false
	if !email.contains("@"):
		return false
	var parts := email.split("@")
	if parts.size() != 2:
		return false
	if parts[0].is_empty() or parts[1].is_empty():
		return false
	if parts[1].find(".") == -1:
		return false
	return true


func _validate_account_password(password: String) -> String:
	if password.is_empty():
		return "Ingresa una contraseña para la cuenta."
	if password.length() < 3 or password.length() > 15:
		return "La contraseña debe tener entre 3 y 15 caracteres."
	for c in password:
		if !Utils.LegalCharacter(c):
			return "El caracter [%s] no está permitido en la contraseña." % c
	return ""
