extends Node

const CREDENTIALS_FILE = "user://saved_credentials.dat"

func save_credentials(username: String, password: String) -> void:
	var file = FileAccess.open(CREDENTIALS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(username + "\n" + password)
		file.close()

func load_credentials() -> Dictionary:
	if FileAccess.file_exists(CREDENTIALS_FILE):
		var file = FileAccess.open(CREDENTIALS_FILE, FileAccess.READ)
		if file:
			var username = file.get_line()
			var password = file.get_line()
			file.close()
			return {"username": username, "password": password}
	
	return {"username": "", "password": ""}

func clear_credentials() -> void:
	if FileAccess.file_exists(CREDENTIALS_FILE):
		DirAccess.remove_absolute(CREDENTIALS_FILE)
