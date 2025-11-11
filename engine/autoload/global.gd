extends Node

var username:String = ""
var skillPoints:int = 0

# Control de logging para paquetes salientes al servidor
var log_outgoing_packets:bool = true

# Control de visibilidad global
var show_player_names:bool = true
var show_fps_counter:bool = false

signal dialog_font_size_changed(value:int)
signal console_font_size_changed(value:int)
signal name_font_size_changed(value:int)
signal custom_cursor_changed(value:bool)


# Opción para usar cursor personalizado
var _useCustomCursor:bool = false

var useCustomCursor:bool:
	set(value):
		_useCustomCursor = value
		emit_signal("custom_cursor_changed", _useCustomCursor)
	get:
		return _useCustomCursor

var _dialogFontSize:int = 12

var dialogFontSize:int:
	set(value):
		_dialogFontSize = clamp(value, 10, 16)
		emit_signal("dialog_font_size_changed", _dialogFontSize)
	get:
		return _dialogFontSize

var _consoleFontSize:int = 12

var consoleFontSize:int:
	set(value):
		_consoleFontSize = clamp(value, 10, 16)
		emit_signal("console_font_size_changed", _consoleFontSize)
	get:
		return _consoleFontSize

var _nameFontSize:int = 14

var nameFontSize:int:
	set(value):
		_nameFontSize = clamp(value, 11, 30)
		emit_signal("name_font_size_changed", _nameFontSize)
	get:
		return _nameFontSize

func get_timestamp() -> String:
	var time = Time.get_time_dict_from_system()
	return " [%02d:%02d:%02d]" % [time.hour, time.minute, time.second]


func _ready() -> void:
	# Cargar configuración guardada
	var cfg = ConfigFile.new()
	var cfg_path = "user://options.cfg"
	if FileAccess.file_exists(cfg_path):
		var raw_bytes = FileAccess.get_file_as_bytes(cfg_path)
		var sanitized = false
		for i in raw_bytes.size():
			if raw_bytes[i] == 0:
				raw_bytes[i] = 32
				sanitized = true
		if sanitized:
			var file = FileAccess.open(cfg_path, FileAccess.WRITE)
			if file:
				file.store_buffer(raw_bytes)
	if cfg.load(cfg_path) == OK:
		var bus = AudioServer.get_bus_index("Master")
		var saved_db = cfg.get_value("audio", "volume_db", AudioServer.get_bus_volume_db(bus))
		AudioServer.set_bus_volume_db(bus, saved_db)
		var saved_fs = cfg.get_value("ui", "dialog_font_size", dialogFontSize)
		dialogFontSize = int(saved_fs)
		var saved_console_fs = cfg.get_value("ui", "console_font_size", consoleFontSize)
		consoleFontSize = int(saved_console_fs)
		var saved_name_fs = cfg.get_value("ui", "name_font_size", nameFontSize)
		nameFontSize = int(saved_name_fs)
		
		# Cargar configuración de cursor personalizado
		var saved_cursor = cfg.get_value("ui", "use_custom_cursor", useCustomCursor)
		useCustomCursor = bool(saved_cursor)
