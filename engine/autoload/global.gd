extends Node

var username:String = ""
var skillPoints:int = 0

# Control de logging para paquetes salientes al servidor
var log_outgoing_packets:bool = true

signal dialog_font_size_changed(value:int)
signal custom_cursor_changed(value:bool)
signal chromatic_mode_changed(value:int)

# Modos cromáticos (0 = desactivado, 1 = deuteranopia, 2 = protanopia, 3 = tritanopia)
var _chromaticMode:int = 0

var chromaticMode:int:
	set(value):
		_chromaticMode = value
		emit_signal("chromatic_mode_changed", _chromaticMode)
	get:
		return _chromaticMode

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

func get_timestamp() -> String:
	var time = Time.get_time_dict_from_system()
	return " [%02d:%02d:%02d]" % [time.hour, time.minute, time.second]

func _ready() -> void:
	# Cargar configuración guardada
	var cfg = ConfigFile.new()
	if cfg.load("user://options.cfg") == OK:
		var bus = AudioServer.get_bus_index("Master")
		var saved_db = cfg.get_value("audio", "volume_db", AudioServer.get_bus_volume_db(bus))
		AudioServer.set_bus_volume_db(bus, saved_db)
		var saved_fs = cfg.get_value("ui", "dialog_font_size", dialogFontSize)
		dialogFontSize = int(saved_fs)
		
		# Cargar configuración de cursor personalizado
		var saved_cursor = cfg.get_value("ui", "use_custom_cursor", useCustomCursor)
		useCustomCursor = bool(saved_cursor)
		
		# Cargar configuración de modo cromático
		var saved_chromaticMode = cfg.get_value("ui", "chromatic_mode", chromaticMode)
		chromaticMode = int(saved_chromaticMode)
		
