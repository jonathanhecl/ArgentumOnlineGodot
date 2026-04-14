extends PanelContainer
class_name LoginPanel

signal submit 
signal register
signal quit_requested
signal error(message:String)

func _ready() -> void:
	%Reg.pressed.connect(func(): register.emit())
	%Exit.pressed.connect(_OnButtonExitPressed)
	%ShowPasswordButton.toggled.connect(_on_show_password_toggled)
	%ShowPasswordButton.toggle_mode = true
	%ShowPasswordButton.button_pressed = false
	%Username.placeholder_text = "correo@dominio.com"
	%Password.placeholder_text = "Contraseña"
	
	# Load saved credentials if they exist
	var credentials = SavedCredentials.load_credentials()
	if credentials.username != "" and credentials.password != "":
		%Username.text = credentials.username
		%Password.text = credentials.password
		%RememberPassword.button_pressed = true

func _on_show_password_toggled(button_pressed: bool) -> void:
	%Password.secret = !button_pressed
	if button_pressed:
		%ShowPasswordButton.text = "🙈"
		%ShowPasswordButton.tooltip_text = "Ocultar contraseña"
	else:
		%ShowPasswordButton.text = "👁️"
		%ShowPasswordButton.tooltip_text = "Mostrar contraseña"

func GetUsername() -> String:
	return %Username.text
	
func GetPassword() -> String:
	return %Password.text

func EnableAuthControls() -> void:
	%Submit.disabled = false
	%Reg.disabled = false
	%Username.editable = true
	%Password.editable = true
	
func DisableAuthControls() -> void:
	%Submit.disabled = true
	%Reg.disabled = true
	%Username.editable = false
	%Password.editable = false


func SetCredentials(username: String, password: String) -> void:
	%Username.text = username
	%Password.text = password


func _OnButtonLoginPressed() -> void:
	var email: String = %Username.text.strip_edges()
	if email.is_empty():
		error.emit("Escriba el email de la cuenta")
		return 
		
	if !_is_valid_email(email):
		error.emit("Ingrese un email válido para la cuenta")
		return
	
	if %Password.text.is_empty():
		error.emit("Escriba la contraseña de la cuenta")
		return
		
	if %Password.text.length() < 3 || %Password.text.length() > 15:
		error.emit("La contraseña de la cuenta tiene que tener un mínimo de 3 caracteres y un máximo de 15 caracteres")
		return
		
	for i in %Password.text:
		if !Utils.LegalCharacter(i):
			error.emit("Contraseña inválida: El caracter [{0}] no está permitido".format([i]))
			return
			
	Global.username = email
	
	# Save credentials if checkbox is checked
	if %RememberPassword.button_pressed:
		SavedCredentials.save_credentials(%Username.text, %Password.text)
	else:
		SavedCredentials.clear_credentials()
	
	submit.emit()


func _OnButtonExitPressed() -> void:
	quit_requested.emit()


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
