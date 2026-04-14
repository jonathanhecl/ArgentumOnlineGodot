extends Node

const CREDENTIALS_FILE = "user://saved_credentials.dat"

var _is_web: bool = false

func _ready() -> void:
	_is_web = OS.has_feature("web")

func save_credentials(username: String, password: String) -> void:
	if _is_web:
		# En web, usar JavaScript para guardar en localStorage
		JavaScriptBridge.eval("localStorage.setItem('ao_username', '%s')" % username.replace("'", "\\'"))
		JavaScriptBridge.eval("localStorage.setItem('ao_password', '%s')" % password.replace("'", "\\'"))
		return
	
	var file = FileAccess.open(CREDENTIALS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(username + "\n" + password)
		file.close()

func load_credentials() -> Dictionary:
	if _is_web:
		# En web, usar JavaScript para leer de localStorage
		var username = JavaScriptBridge.eval("localStorage.getItem('ao_username') || ''")
		var password = JavaScriptBridge.eval("localStorage.getItem('ao_password') || ''")
		return {"username": username, "password": password}
	
	if FileAccess.file_exists(CREDENTIALS_FILE):
		var file = FileAccess.open(CREDENTIALS_FILE, FileAccess.READ)
		if file:
			var username = file.get_line()
			var password = file.get_line()
			file.close()
			return {"username": username, "password": password}
	
	return {"username": "", "password": ""}

func clear_credentials() -> void:
	if _is_web:
		JavaScriptBridge.eval("localStorage.removeItem('ao_username')")
		JavaScriptBridge.eval("localStorage.removeItem('ao_password')")
		return
	
	if FileAccess.file_exists(CREDENTIALS_FILE):
		DirAccess.remove_absolute(CREDENTIALS_FILE)
