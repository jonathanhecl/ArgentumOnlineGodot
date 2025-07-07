extends Window

# Referencias a los campos de entrada
@onready var current_password_input: LineEdit = $VBoxContainer/FormContainer/CurrentPasswordInput
@onready var new_password_input: LineEdit = $VBoxContainer/FormContainer/NewPasswordInput
@onready var confirm_password_input: LineEdit = $VBoxContainer/FormContainer/ConfirmPasswordInput
@onready var accept_button: Button = $VBoxContainer/ButtonsContainer/AcceptButton
@onready var cancel_button: Button = $VBoxContainer/ButtonsContainer/CancelButton

# Referencias a los botones de mostrar/ocultar
@onready var current_password_toggle: Button = $VBoxContainer/FormContainer/CurrentPasswordToggle
@onready var new_password_toggle: Button = $VBoxContainer/FormContainer/NewPasswordToggle
@onready var confirm_password_toggle: Button = $VBoxContainer/FormContainer/ConfirmPasswordToggle

# Referencia al hub controller
var hub_controller: HubController

# Timer para debounce del mensaje de error
var debounce_timer: Timer
var last_error_message: String = ""

# Referencia al label de error
@onready var error_label: Label = $VBoxContainer/ErrorLabel

func _ready():
	# Conectar señales
	accept_button.pressed.connect(_on_accept_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	close_requested.connect(_on_cancel_pressed)
	
	# Conectar señales de los botones de mostrar/ocultar
	current_password_toggle.pressed.connect(_on_current_password_toggle)
	new_password_toggle.pressed.connect(_on_new_password_toggle)
	confirm_password_toggle.pressed.connect(_on_confirm_password_toggle)
	
	# Conectar señales de texto cambiado para validación
	current_password_input.text_changed.connect(_on_text_changed)
	new_password_input.text_changed.connect(_on_text_changed)
	confirm_password_input.text_changed.connect(_on_text_changed)
	
	# Configurar ventana
	title = "Cambiar Contraseña"
	
	# Configurar timer para debounce
	debounce_timer = Timer.new()
	debounce_timer.wait_time = 0.5  # 500ms
	debounce_timer.one_shot = true
	debounce_timer.timeout.connect(_on_debounce_timeout)
	add_child(debounce_timer)
	
	# Validar campos inicialmente
	_validate_fields()

func _on_text_changed(_text: String):
	_validate_fields()

func _validate_fields():
	var current_valid = current_password_input.text.length() > 0
	var new_valid = new_password_input.text.length() > 0
	var passwords_match = confirm_password_input.text == new_password_input.text
	var confirm_valid = passwords_match and confirm_password_input.text.length() > 0
	
	accept_button.disabled = not (current_valid and new_valid and confirm_valid)
	
	# Detener cualquier timer pendiente
	debounce_timer.stop()
	
	# Si las contraseñas coinciden, limpiar cualquier mensaje de error
	if new_password_input.text.length() > 0 and confirm_password_input.text.length() > 0:
		if passwords_match:
			last_error_message = ""
			error_label.text = ""
		else:
			# Si no coinciden, programar el mensaje de error con debounce
			last_error_message = "Las contraseñas no coinciden."
			debounce_timer.start()
	else:
		# Si alguno de los campos está vacío, limpiar mensajes
		last_error_message = ""
		error_label.text = ""

func _on_accept_pressed():
	var current_password = current_password_input.text
	var new_password = new_password_input.text
	var confirm_password = confirm_password_input.text
	
	# Validaciones
	if current_password.is_empty():
		_show_error("Debe ingresar su contraseña actual.")
		return
	
	if new_password.is_empty():
		_show_error("Debe ingresar la nueva contraseña.")
		return
	
	if confirm_password.is_empty():
		_show_error("Debe confirmar la nueva contraseña.")
		return
	
	if new_password != confirm_password:
		_show_error("Las contraseñas no coinciden.")
		return
	
	# Enviar solicitud de cambio de contraseña al servidor (como en VB6)
	GameProtocol.WriteChangePassword(current_password, new_password)
	
	# Mostrar mensaje de confirmación
	if hub_controller:
		hub_controller.ShowConsoleMessage("Solicitud de cambio de contraseña enviada al servidor.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
	
	# Limpiar campos y cerrar ventana
	_clear_fields()
	hide()

func _on_cancel_pressed():
	_clear_fields()
	hide()

func _clear_fields():
	current_password_input.text = ""
	new_password_input.text = ""
	confirm_password_input.text = ""

func _show_error(message: String):
	error_label.text = message

func show_window(controller):
	hub_controller = controller
	_clear_fields()
	popup_centered()
	current_password_input.grab_focus()

# Funciones para los botones de mostrar/ocultar contraseña
func _on_current_password_toggle():
	current_password_input.secret = not current_password_input.secret
	current_password_toggle.text = "👁" if current_password_input.secret else "🙈"

func _on_new_password_toggle():
	new_password_input.secret = not new_password_input.secret
	new_password_toggle.text = "👁" if new_password_input.secret else "🙈"

func _on_confirm_password_toggle():
	confirm_password_input.secret = not confirm_password_input.secret
	confirm_password_toggle.text = "👁" if confirm_password_input.secret else "🙈"

# Función que se ejecuta cuando el timer de debounce termina
func _on_debounce_timeout():
	if last_error_message != "":
		error_label.text = last_error_message
	else:
		error_label.text = ""
