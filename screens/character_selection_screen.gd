extends Control
class_name CharacterSelectionScreen

const MAX_CHARACTERS = 10

# Señales
signal character_selected(character_name:String)
signal create_character_requested()
signal delete_character_requested(character_name:String)
signal logout_requested()

# Lista de personajes de la cuenta (máximo 10)
var characters: Array[Dictionary] = []
var account_name: String = ""
var selected_index: int = -1  # 0-9 para los 10 slots

# Referencias de UI
@onready var account_label = %AccountLabel
@onready var character_grid = %CharacterGrid
@onready var char_info_panel = %CharInfoPanel
@onready var char_name_label = %CharNameLabel
@onready var char_class_label = %CharClassLabel
@onready var char_race_label = %CharRaceLabel  
@onready var char_level_label = %CharLevelLabel
@onready var char_gold_label = %CharGoldLabel
@onready var char_map_label = %CharMapLabel
@onready var delete_button = %DeleteButton
@onready var create_button = %CreateButton
@onready var connect_button = %ConnectButton
@onready var logout_button = %LogoutButton

func _ready() -> void:
	# Conectar señales de botones
	delete_button.pressed.connect(_on_delete_pressed)
	create_button.pressed.connect(_on_create_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	
	# Mostrar nombre de cuenta
	account_label.text = account_name
	
	# Crear los 10 slots de personajes
	_create_character_slots()
	
	# Actualizar vista de personajes
	_update_character_view()

func set_account_data(acc_name: String, char_list: Array[Dictionary]) -> void:
	"""Establece los datos de la cuenta y los personajes (como en VB6)"""
	account_name = acc_name
	characters = char_list
	
	# Asegurar que no haya más de 10 personajes
	if characters.size() > MAX_CHARACTERS:
		characters.resize(MAX_CHARACTERS)

func _create_character_slots() -> void:
	"""Crea los 10 slots visuales para personajes (como picChar en VB6)"""
	for i in range(MAX_CHARACTERS):
		var slot = Panel.new()
		slot.name = "CharSlot" + str(i)
		slot.custom_minimum_size = Vector2(100, 120)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Sprite del personaje (placeholder por ahora)
		var sprite_container = ColorRect.new()
		sprite_container.name = "SpriteContainer"
		sprite_container.custom_minimum_size = Vector2(76, 80)
		sprite_container.color = Color.BLACK
		vbox.add_child(sprite_container)
		
		# Nombre del personaje
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text = ""
		vbox.add_child(name_label)
		
		slot.add_child(vbox)
		
		# Conectar eventos de click
		slot.gui_input.connect(_on_slot_gui_input.bind(i))
		
		character_grid.add_child(slot)

func _update_character_view() -> void:
	"""Actualiza la vista de todos los personajes (como Form_Load en VB6)"""
	for i in range(MAX_CHARACTERS):
		var slot = character_grid.get_node_or_null("CharSlot" + str(i))
		if not slot:
			continue
			
		var name_label = slot.get_node_or_null("VBoxContainer/NameLabel")
		if not name_label:
			continue
		
		# Si hay un personaje en este slot
		if i < characters.size():
			var char_data = characters[i]
			name_label.text = char_data.get("name", "")
			# TODO: Renderizar sprite del personaje usando body, head, weapon, etc.
		else:
			name_label.text = ""

func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	"""Maneja click y double-click en slots (como picChar_Click y picChar_DblClick)"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				# Double click: conectar o crear personaje
				_on_slot_double_click(slot_index)
			else:
				# Single click: seleccionar personaje
				_on_slot_click(slot_index)

func _on_slot_click(slot_index: int) -> void:
	"""Selecciona un personaje y muestra su información (como picChar_Click)"""
	selected_index = slot_index
	
	if slot_index < characters.size():
		var char_data = characters[slot_index]
		_show_character_info(char_data)
	else:
		_clear_character_info()

func _on_slot_double_click(slot_index: int) -> void:
	"""Double-click: conectar si existe, crear si está vacío (como picChar_DblClick)"""
	if slot_index < characters.size():
		# Hay personaje, conectar
		var char_name = characters[slot_index].get("name", "")
		if not char_name.is_empty():
			character_selected.emit(char_name)
	else:
		# Slot vacío, crear personaje
		create_character_requested.emit()

func _show_character_info(char_data: Dictionary) -> void:
	"""Muestra información del personaje seleccionado (como lblCharData en VB6)"""
	char_name_label.text = "Nombre: " + char_data.get("name", "")
	
	# Convertir class de byte a nombre
	var class_id = char_data.get("class", 0)
	var char_class = Consts.ClassNames.get(class_id, "Desconocido")
	char_class_label.text = "Clase: " + char_class
	
	# Convertir race de byte a nombre
	var race_id = char_data.get("race", 0)
	var char_race = Consts.RaceNames.get(race_id, "Desconocido")
	char_race_label.text = "Raza: " + char_race
	
	char_level_label.text = "Nivel: " + str(char_data.get("level", 1))
	char_gold_label.text = "Oro: " + str(char_data.get("gold", 0))
	char_map_label.text = "Mapa: " + str(char_data.get("map", 1))

func _clear_character_info() -> void:
	"""Limpia el panel de información"""
	char_name_label.text = ""
	char_class_label.text = ""
	char_race_label.text = ""
	char_level_label.text = ""
	char_gold_label.text = ""
	char_map_label.text = ""

func _on_delete_pressed() -> void:
	"""Borrar personaje seleccionado (como uAOBorrarPersonaje_Click)"""
	if selected_index < 0 or selected_index >= characters.size():
		_show_error("No hay ningún personaje seleccionado")
		return
	
	var char_name = characters[selected_index].get("name", "")
	if char_name.is_empty():
		_show_error("No hay ningún personaje seleccionado")
		return
	
	# Confirmar borrado
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "¿Estás seguro de que deseas borrar el personaje '" + char_name + "'?"
	confirm.title = "Confirmar borrado"
	confirm.confirmed.connect(func():
		delete_character_requested.emit(char_name)
		confirm.queue_free()
	)
	add_child(confirm)
	confirm.popup_centered()

func _on_create_pressed() -> void:
	"""Crear nuevo personaje (como uAOCrearPersonaje_Click)"""
	if characters.size() >= MAX_CHARACTERS:
		_show_error("Ya tienes el máximo de personajes permitidos")
		return
	
	create_character_requested.emit()

func _on_connect_pressed() -> void:
	"""Conectar con personaje seleccionado (como uAOConectar_Click)"""
	if selected_index < 0 or selected_index >= characters.size():
		_show_error("Debes seleccionar un personaje")
		return
	
	var char_name = characters[selected_index].get("name", "")
	if char_name.is_empty():
		_show_error("Debes seleccionar un personaje")
		return
	
	character_selected.emit(char_name)

func _on_logout_pressed() -> void:
	"""Cerrar sesión (como uAOSalir_Click)"""
	logout_requested.emit()

func _show_error(message: String) -> void:
	"""Muestra un mensaje de error"""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Error"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
