extends Control
class_name CharacterSelectionScreen

const MAX_CHARACTERS = 10  # Máximo de personajes por cuenta

# Señales
signal character_selected(character_name: String)
signal create_character_requested()
signal delete_character_requested(character_name: String)
signal logout_requested()

# Lista de personajes de la cuenta (máximo 10)
var characters: Array[Dictionary] = []
var account_name: String = ""
var selected_index: int = -1 # 0-9 para los 10 slots

# Referencias a los slots y sus componentes
var _slot_buttons: Array[Button] = []
var _slot_name_labels: Array[Label] = []
var _slot_renderers: Array[CharacterRenderer] = []

# Referencias de UI
@onready var account_label = %AccountLabel
@onready var character_grid = %CharacterGrid
@onready var char_info_panel = %InfoPanel
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
	print("[CharSelection] _ready() llamado. Characters size: ", characters.size())
	
	# Conectar señales de botones si existen
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)
	if create_button:
		create_button.pressed.connect(_on_create_pressed)
	if connect_button:
		connect_button.pressed.connect(_on_connect_pressed)
	if logout_button:
		logout_button.pressed.connect(_on_logout_pressed)
	
	# Mostrar nombre de cuenta
	if account_label:
		account_label.text = "Cuenta: " + account_name
	
	# Crear los 10 slots de personajes
	_create_character_slots()
	
	# IMPORTANTE: Esperar un frame para que los slots estén en el árbol
	await get_tree().process_frame
	
	# Actualizar vista de personajes (si ya hay datos)
	if characters.size() > 0:
		print("[CharSelection] Actualizando vista en _ready con ", characters.size(), " personajes")
		_update_character_view()
		# Auto-seleccionar el primer personaje
		_on_slot_click(0)

func set_account_data(acc_name: String, char_list: Array[Dictionary]) -> void:
	"""Establece los datos de la cuenta y los personajes (como en VB6)"""
	print("[CharSelection] set_account_data llamado. Account: ", acc_name, ", Characters: ", char_list.size())
	
	account_name = acc_name
	characters = char_list
	
	# Debug: imprimir los personajes recibidos
	for i in range(characters.size()):
		print("[CharSelection] Personaje ", i, ": ", characters[i].get("name", "SIN NOMBRE"))
	
	# Asegurar que no haya más de 10 personajes
	if characters.size() > MAX_CHARACTERS:
		characters.resize(MAX_CHARACTERS)
	
	# Actualizar la vista si ya estamos en el árbol de escena
	if is_inside_tree():
		print("[CharSelection] Ya en árbol, actualizando vista...")
		if account_label:
			account_label.text = "Cuenta: " + account_name
		
		# Esperar un frame para asegurar que todo esté listo
		await get_tree().process_frame
		_update_character_view()
		
		# Auto-seleccionar el primer personaje si existe
		if characters.size() > 0:
			print("[CharSelection] Auto-seleccionando primer personaje")
			_on_slot_click(0)

func _create_character_slots() -> void:
	"""Crea los 10 slots visuales para personajes (como picChar en VB6)"""
	# Limpiar slots existentes si los hay
	for child in character_grid.get_children():
		child.queue_free()
	
	# Limpiar arrays de referencias
	_slot_buttons.clear()
	_slot_name_labels.clear()
	_slot_renderers.clear()
		
	for i in range(MAX_CHARACTERS):
		# Usar Button en lugar de PanelContainer para mejor manejo de clicks
		var slot = Button.new()
		slot.name = "CharSlot" + str(i)
		slot.custom_minimum_size = Vector2(120, 120)  # Slots cuadrados
		slot.flat = false
		
		# Estilo base del botón
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color("1a1a1a")
		style_normal.border_width_left = 1
		style_normal.border_width_top = 1
		style_normal.border_width_right = 1
		style_normal.border_width_bottom = 1
		style_normal.border_color = Color("333333")
		style_normal.corner_radius_top_left = 4
		style_normal.corner_radius_top_right = 4
		style_normal.corner_radius_bottom_right = 4
		style_normal.corner_radius_bottom_left = 4
		
		var style_hover = style_normal.duplicate()
		style_hover.border_color = Color("555555")
		style_hover.bg_color = Color("252525")
		
		var style_pressed = style_normal.duplicate()
		style_pressed.border_color = Color("00aaff")
		style_pressed.bg_color = Color("2a2a2a")
		
		slot.add_theme_stylebox_override("normal", style_normal)
		slot.add_theme_stylebox_override("hover", style_hover)
		slot.add_theme_stylebox_override("pressed", style_pressed)
		
		# Contenedor interno
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Contenedor para el sprite del personaje
		var sprite_container = SubViewportContainer.new()
		sprite_container.name = "SpriteContainer"
		sprite_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite_container.custom_minimum_size = Vector2(64, 70)
		sprite_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sprite_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sprite_container.stretch = true
		
		# SubViewport para renderizar el personaje
		var viewport = SubViewport.new()
		viewport.name = "SubViewport"
		viewport.size = Vector2i(64, 70)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		sprite_container.add_child(viewport)
		
		# Crear el CharacterRenderer para este slot
		var char_renderer = _create_character_renderer()
		char_renderer.position = Vector2(32, 58) # Centrar en el viewport (x=mitad, y=abajo)
		viewport.add_child(char_renderer)
		
		vbox.add_child(sprite_container)
		
		# Nombre del personaje
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text = "" # Iniciar vacío, se actualizará en _update_character_view
		name_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(name_label)
		
		slot.add_child(vbox)
		
		# Guardar referencias directas
		_slot_buttons.append(slot)
		_slot_name_labels.append(name_label)
		_slot_renderers.append(char_renderer)
		
		# Conectar señal de pressed en lugar de gui_input
		slot.pressed.connect(_on_slot_pressed.bind(i))
		
		character_grid.add_child(slot)

func _update_character_view() -> void:
	"""Actualiza la vista de todos los personajes (como Form_Load en VB6)"""
	print("[CharSelection] Actualizando vista con ", characters.size(), " personajes")
	print("[CharSelection] Slots creados: ", _slot_buttons.size())
	
	for i in range(mini(MAX_CHARACTERS, _slot_buttons.size())):
		var name_label = _slot_name_labels[i]
		var char_renderer = _slot_renderers[i]
		
		# Resetear estilo
		_update_slot_style(i, false)
		
		# Si hay un personaje en este slot
		if i < characters.size():
			var char_data = characters[i]
			var char_name = char_data.get("name", "")
			print("[CharSelection] Slot ", i, " - Personaje: '", char_name, "'")
			
			# Actualizar texto y color
			name_label.text = char_name if not char_name.is_empty() else "Sin nombre"
			name_label.add_theme_color_override("font_color", Color("ffffff"))
			name_label.visible = true
			
			# Actualizar el renderer con los datos del personaje
			_update_character_renderer(char_renderer, char_data)
			char_renderer.visible = true
			
		else:
			print("[CharSelection] Slot ", i, " - Vacío")
			name_label.text = "Vacío"
			name_label.add_theme_color_override("font_color", Color("555555"))
			name_label.visible = true
			
			# Ocultar el renderer para slots vacíos
			char_renderer.visible = false

func _create_character_renderer() -> CharacterRenderer:
	"""Crea un CharacterRenderer programáticamente para preview"""
	var renderer = CharacterRenderer.new()
	renderer.name = "CharRenderer"
	
	# Crear los AnimatedSprite2D necesarios
	var body_sprite = AnimatedSprite2D.new()
	body_sprite.name = "Body"
	renderer.add_child(body_sprite)
	
	var head_sprite = AnimatedSprite2D.new()
	head_sprite.name = "Head"
	head_sprite.position = Vector2(0, -5)
	renderer.add_child(head_sprite)
	
	var helmet_sprite = AnimatedSprite2D.new()
	helmet_sprite.name = "Helmet"
	helmet_sprite.position = Vector2(0, -20)
	renderer.add_child(helmet_sprite)
	
	var shield_sprite = AnimatedSprite2D.new()
	shield_sprite.name = "Shield"
	renderer.add_child(shield_sprite)
	
	var weapon_sprite = AnimatedSprite2D.new()
	weapon_sprite.name = "Weapon"
	renderer.add_child(weapon_sprite)
	
	# Asignar las referencias al renderer
	renderer._bodyAnimatedSprite = body_sprite
	renderer._headAnimatedSprite = head_sprite
	renderer._helmetAnimatedSprite = helmet_sprite
	renderer._shieldAnimatedSprite = shield_sprite
	renderer._weaponAnimatedSprite = weapon_sprite
	
	# Cargar sprite frames vacíos por defecto
	var default_frames = load("res://Resources/Character/none.tres")
	body_sprite.sprite_frames = default_frames
	head_sprite.sprite_frames = default_frames
	helmet_sprite.sprite_frames = default_frames
	shield_sprite.sprite_frames = default_frames
	weapon_sprite.sprite_frames = default_frames
	
	return renderer

func _update_character_renderer(char_renderer: CharacterRenderer, char_data: Dictionary) -> void:
	"""Actualiza un CharacterRenderer con los datos del personaje"""
	# Asignar body, head, weapon, shield, helmet
	var body_id = char_data.get("body", 0)
	var head_id = char_data.get("head", 0)
	var weapon_id = char_data.get("weapon", 0)
	var shield_id = char_data.get("shield", 0)
	var helmet_id = char_data.get("helmet", 0)
	
	print("[CharSelection] Renderer - Body: ", body_id, " Head: ", head_id, " Weapon: ", weapon_id)
	
	# Establecer los valores (esto cargará los sprites automáticamente)
	if body_id > 0:
		char_renderer.body = body_id
	if head_id > 0:
		char_renderer.head = head_id
	if weapon_id > 0:
		char_renderer.weapon = weapon_id
	if shield_id > 0:
		char_renderer.shield = shield_id
	if helmet_id > 0:
		char_renderer.helmet = helmet_id
	
	# Reproducir animación de caminar hacia el sur (más dinámico)
	char_renderer.heading = Enums.Heading.South
	char_renderer.Play()  # Animación de caminar en lugar de idle

func _update_slot_style(index: int, selected: bool) -> void:
	var slot = character_grid.get_node_or_null("CharSlot" + str(index))
	if not slot: return
	
	# Para Button, usamos diferentes estados de estilo
	if selected:
		var style_selected = StyleBoxFlat.new()
		style_selected.bg_color = Color("2a2a2a")
		style_selected.border_width_left = 2
		style_selected.border_width_top = 2
		style_selected.border_width_right = 2
		style_selected.border_width_bottom = 2
		style_selected.border_color = Color("00aaff")
		style_selected.corner_radius_top_left = 4
		style_selected.corner_radius_top_right = 4
		style_selected.corner_radius_bottom_right = 4
		style_selected.corner_radius_bottom_left = 4
		slot.add_theme_stylebox_override("normal", style_selected)
	else:
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color("1a1a1a")
		style_normal.border_width_left = 1
		style_normal.border_width_top = 1
		style_normal.border_width_right = 1
		style_normal.border_width_bottom = 1
		style_normal.border_color = Color("333333")
		style_normal.corner_radius_top_left = 4
		style_normal.corner_radius_top_right = 4
		style_normal.corner_radius_bottom_right = 4
		style_normal.corner_radius_bottom_left = 4
		slot.add_theme_stylebox_override("normal", style_normal)

func _on_slot_pressed(slot_index: int) -> void:
	"""Maneja el click en un slot de personaje"""
	print("[CharSelection] Slot presionado: ", slot_index)
	_on_slot_click(slot_index)

func _on_slot_click(slot_index: int) -> void:
	"""Selecciona un personaje y muestra su información (como picChar_Click)"""
	print("[CharSelection] Seleccionando slot: ", slot_index)
	
	# Deseleccionar anterior
	if selected_index != -1:
		_update_slot_style(selected_index, false)
		
	selected_index = slot_index
	
	# Seleccionar nuevo
	_update_slot_style(selected_index, true)
	
	if slot_index < characters.size():
		var char_data = characters[slot_index]
		print("[CharSelection] Mostrando info de: ", char_data.get("name", ""))
		_show_character_info(char_data)
	else:
		print("[CharSelection] Slot vacío, limpiando info")
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
	print("[CharSelection] _show_character_info llamado con: ", char_data)
	print("[CharSelection] char_info_panel es null: ", char_info_panel == null)
	if not char_info_panel:
		print("[CharSelection] ERROR: char_info_panel es null!")
		return
		
	char_name_label.text = "Nombre: " + char_data.get("name", "-")
	
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
	if not char_info_panel:
		return
		
	char_name_label.text = "Nombre: -"
	char_class_label.text = "Clase: -"
	char_race_label.text = "Raza: -"
	char_level_label.text = "Nivel: -"
	char_gold_label.text = "Oro: -"
	char_map_label.text = "Mapa: -"

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
	"""Cerrar sesión - volver a pantalla de login"""
	print("[CharSelection] Cerrar sesión presionado")
	
	# Limpiar datos de cuenta
	Global.account_name = ""
	Global.account_hash = ""
	
	# Desconectar del servidor
	ClientInterface.DisconnectFromHost()
	
	# Volver a pantalla de login
	var login_screen = load("res://screens/login_screen.tscn").instantiate()
	ScreenController.SwitchScreen(login_screen)
	
	# Emitir señal por si alguien la necesita
	logout_requested.emit()

func _show_error(message: String) -> void:
	"""Muestra un mensaje de error"""
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Error"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
