extends AcceptDialog
class_name OptionsWindow

# Ventana de Opciones para ajustar volumen
@onready var slider = $VBox/hbox_volume/SliderVolume
@onready var btn_close = $VBox/HBoxContainer/BtnClose

func _ready() -> void:
	# Inicializar slider con el volumen actual del bus Master
	var bus = AudioServer.get_bus_index("Master")
	slider.value = AudioServer.get_bus_volume_db(bus)
	slider.connect("value_changed", Callable(self, "_on_slider_value_changed"))

func _on_slider_value_changed(value: float) -> void:
	# Ajustar volumen del bus Master en decibeles
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, value)
