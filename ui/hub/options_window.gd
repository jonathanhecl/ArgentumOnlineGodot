extends AcceptDialog
class_name OptionsWindow

@onready var sliderVolume = $VBox/hbox_volume/SliderVolume
@onready var btn_close = $VBox/HBoxContainer/BtnClose
@onready var sliderFontSize = $VBox/hbox_font_size/SliderFontSize

func _ready() -> void:
	get_ok_button().text = "Guardar"
	
	var bus = AudioServer.get_bus_index("Master")
	sliderVolume.value = db_to_linear(AudioServer.get_bus_volume_db(bus))
	sliderVolume.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	sliderFontSize.value = Global.dialogFontSize
	sliderFontSize.connect("value_changed", Callable(self, "_on_slider_font_size_changed"))
	
	# Guardar configuración al confirmar
	connect("confirmed", Callable(self, "_on_save_settings"))

func _on_slider_value_changed(value: float) -> void:
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_slider_font_size_changed(value: float) -> void:
	Global.dialogFontSize = int(value)

func _on_save_settings() -> void:
	var cfg = ConfigFile.new()
	# Cargar existente (si hay) y actualizar valores
	cfg.load("user://options.cfg")
	cfg.set_value("audio", "volume_db", linear_to_db(sliderVolume.value))
	cfg.set_value("ui", "dialog_font_size", sliderFontSize.value)
	cfg.save("user://options.cfg")
