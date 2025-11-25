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
	ClientInterface.dataReceived.connect(_OnDataReceived)
	
	_loginPanel.error.connect(func(message):
		Utils.ShowAlertDialog("Login", message, self))
	
func _OnConnected() -> void:
	# Resetear clave de cifrado al conectar (como en VB6: Security.Redundance = 13)
	Security.reset_redundance()
	
	if _state == State.RegisterAccount:
		# Ir a pantalla de registro de cuenta (requiere email)
		_show_register_account_dialog()
	elif _state == State.LoginAccount:
		# Enviar login de cuenta al servidor
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

func _OnDataReceived(data: PackedByteArray) -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = data
	
	print("[LoginScreen] Received data: ", data.hex_encode())
	
	while stream.get_position() < stream.get_size():
		var packetId = stream.get_u8()
		print("[LoginScreen] Processing Packet ID: ", packetId)
		
		if packetId == Enums.ServerPacketID.ErrorMsg:
			print("[LoginScreen] Handling ErrorMsg")
			_HandleErrorMsg(Utils.GetUnicodeString(stream))
		elif packetId == Enums.ServerPacketID.AccountLogged:
			print("[LoginScreen] Handling AccountLogged (108)")
			_HandleAccountLogged(stream)
			return
		else:
			print("[LoginScreen] Unhandled packet ID: ", packetId, ". Defaulting to _HandleLogged (GameScreen).")
			_HandleLogged(data)
			return

func _HandleErrorMsg(message: String) -> void:
	Utils.ShowAlertDialog("Server", message, self)
	ClientInterface.DisconnectFromHost()

func _HandleAccountLogged(stream: StreamPeerBuffer) -> void:
	"""Manejar el paquete AccountLogged que contiene la lista de personajes"""
	var account_name = Utils.GetUnicodeString(stream)
	var account_hash = Utils.GetUnicodeString(stream)
	var num_characters = stream.get_u8()
	
	print("Account logged: ", account_name, " Hash: ", account_hash, " Characters: ", num_characters)
	
	var characters: Array[Dictionary] = []
	for i in range(num_characters):
		var char_name = Utils.GetUnicodeString(stream)
		var char_body = stream.get_16()
		var char_head = stream.get_16()
		var char_weapon = stream.get_16()
		var char_shield = stream.get_16()
		var char_helmet = stream.get_16()
		var char_class = stream.get_u8()
		var char_race = stream.get_u8()
		var char_map = stream.get_16()
		var char_level = stream.get_u8()
		var char_gold = stream.get_32()
		var char_criminal = stream.get_u8() != 0 # Boolean
		var char_dead = stream.get_u8() != 0 # Boolean
		var char_gm = stream.get_u8() != 0 # Boolean
		
		characters.append({
			"name": char_name,
			"level": char_level,
			"class": char_class,
			"body": char_body,
			"head": char_head,
			"weapon": char_weapon,
			"shield": char_shield,
			"helmet": char_helmet,
			"race": char_race,
			"map": char_map,
			"gold": char_gold,
			"criminal": char_criminal,
			"dead": char_dead,
			"gm": char_gm
		})
	
	# Guardar datos de cuenta en Global
	Global.account_name = account_name
	Global.account_hash = account_hash
	
	# Cambiar a pantalla de selección de personajes
	var char_selection_screen = CharacterSelectionScene.instantiate()
	char_selection_screen.set_account_data(account_name, characters)
	
	# Conectar señales
	char_selection_screen.character_selected.connect(_on_character_selected)
	char_selection_screen.create_character_requested.connect(_on_create_character_requested)
	char_selection_screen.logout_requested.connect(_on_logout_requested)
	
	ScreenController.SwitchScreen(char_selection_screen)

func _HandleLogged(data: PackedByteArray) -> void:
	# Solo para compatibilidad con el sistema antiguo
	var screen = load("uid://b2dyxo3826bub").instantiate() as GameScreen
	screen.networkMessages.append(data)
	
	ScreenController.SwitchScreen(screen)
		
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
