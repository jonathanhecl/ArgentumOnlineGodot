extends Control
class_name CharacterSelectionScreen

const MAX_CHARACTERS = 10

# Señales
signal character_selected(character_name: String)
signal create_character_requested()
signal delete_character_requested(character_name: String)
signal logout_requested()

# Datos
var characters: Array[Dictionary] = []
var account_name: String = ""
var selected_index: int = -1

# UI References
@onready var account_label = %AccountLabel
@onready var character_list = %CharacterList
@onready var char_preview_anchor = %CharacterPreviewAnchor
@onready var char_name_label = %CharNameLabel
@onready var char_details_label = %CharDetailsLabel
@onready var char_location_label = %CharLocationLabel

@onready var connect_button = %ConnectButton
@onready var create_button = %CreateButton
@onready var delete_button = %DeleteButton
@onready var logout_button = %LogoutButton

# Preview Renderer
var _preview_renderer: CharacterRenderer

# List Buttons
var _list_buttons: Array[Button] = []

func _ready() -> void:
	# Conectar señales
	if delete_button: delete_button.pressed.connect(_on_delete_pressed)
	if create_button: create_button.pressed.connect(_on_create_pressed)
	if connect_button: connect_button.pressed.connect(_on_connect_pressed)
	if logout_button: logout_button.pressed.connect(_on_logout_pressed)
	
	if account_label:
		account_label.text = "Cuenta: " + account_name
		
	# Crear el renderer para el preview central
	_create_preview_renderer()
	
	# Limpiar labels
	_clear_character_info()
	
	await get_tree().process_frame
	
	if characters.size() > 0:
		_update_character_list()
		# Seleccionar el primero por defecto
		_on_char_list_item_pressed(0)

func set_account_data(acc_name: String, char_list: Array[Dictionary]) -> void:
	account_name = acc_name
	characters = char_list
	
	if characters.size() > MAX_CHARACTERS:
		characters.resize(MAX_CHARACTERS)
		
	if is_inside_tree():
		if account_label:
			account_label.text = "Cuenta: " + account_name
		
		await get_tree().process_frame
		_update_character_list()
		
		if characters.size() > 0:
			_on_char_list_item_pressed(0)
		else:
			_clear_character_info()

func _create_preview_renderer() -> void:
	if _preview_renderer:
		_preview_renderer.queue_free()
		
	_preview_renderer = CharacterRenderer.new()
	_preview_renderer.name = "PreviewRenderer"
	# Escalar el renderer para que se vea grande
	_preview_renderer.scale = Vector2(4, 4)
	
	# Crear sprites
	var body = AnimatedSprite2D.new(); _preview_renderer.add_child(body)
	var head = AnimatedSprite2D.new(); head.position = Vector2(0, -5); _preview_renderer.add_child(head)
	var helmet = AnimatedSprite2D.new(); helmet.position = Vector2(0, -20); _preview_renderer.add_child(helmet)
	var shield = AnimatedSprite2D.new(); _preview_renderer.add_child(shield)
	var weapon = AnimatedSprite2D.new(); _preview_renderer.add_child(weapon)
	
	_preview_renderer._bodyAnimatedSprite = body
	_preview_renderer._headAnimatedSprite = head
	_preview_renderer._helmetAnimatedSprite = helmet
	_preview_renderer._shieldAnimatedSprite = shield
	_preview_renderer._weaponAnimatedSprite = weapon
	
	# Cargar frames vacíos
	var default_frames = load("res://Resources/Character/none.tres")
	body.sprite_frames = default_frames
	head.sprite_frames = default_frames
	helmet.sprite_frames = default_frames
	shield.sprite_frames = default_frames
	weapon.sprite_frames = default_frames
	
	char_preview_anchor.add_child(_preview_renderer)

func _update_character_list() -> void:
	# Limpiar lista
	for child in character_list.get_children():
		child.queue_free()
	_list_buttons.clear()
	
	# Crear botones para cada personaje
	for i in range(characters.size()):
		var char_data = characters[i]
		var char_name = char_data.get("name", "Sin Nombre")
		var char_lvl = str(char_data.get("level", 1))
		var class_id = char_data.get("class", 0)
		var char_class = Consts.ClassNames.get(class_id, "Clase")
		
		var btn = Button.new()
		btn.text = char_name + " (Nvl " + char_lvl + " " + char_class + ")"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 40)
		
		# Estilo básico
		btn.flat = false
		
		btn.pressed.connect(_on_char_list_item_pressed.bind(i))
		
		character_list.add_child(btn)
		_list_buttons.append(btn)
		
	# Si hay espacio para crear más (hasta MAX), podríamos mostrar slots vacíos o simplemente dejar el botón "Crear" abajo
	# En WoW se muestran solo los existentes y un botón "Crear Nuevo" si hay espacio.
	# Aquí ya tenemos el botón "Crear Personaje" en el panel de acciones.

func _on_char_list_item_pressed(index: int) -> void:
	selected_index = index
	
	# Actualizar estilos de botones (highlight selected)
	for i in range(_list_buttons.size()):
		var btn = _list_buttons[i]
		if i == index:
			btn.modulate = Color(1, 1, 0) # Amarillo para seleccionado
		else:
			btn.modulate = Color(1, 1, 1)
			
	# Actualizar preview central
	if index >= 0 and index < characters.size():
		var char_data = characters[index]
		_update_preview_info(char_data)
		_update_preview_renderer(char_data)
		
		# Habilitar botones
		connect_button.disabled = false
		delete_button.disabled = false
	else:
		_clear_character_info()
		connect_button.disabled = true
		delete_button.disabled = true

func _update_preview_info(char_data: Dictionary) -> void:
	char_name_label.text = char_data.get("name", "Sin Nombre")
	
	var lvl = str(char_data.get("level", 1))
	var class_id = char_data.get("class", 0)
	var race_id = char_data.get("race", 0)
	var map_id = str(char_data.get("map", 1))
	
	var class_player = Consts.ClassNames.get(class_id, "Desconocido")
	var race_player = Consts.RaceNames.get(race_id, "Desconocido")
	
	char_details_label.text = "Nivel " + lvl + " " + race_player + " " + class_player
	char_location_label.text = "Ubicación: Mapa " + map_id
	
	char_name_label.visible = true
	char_details_label.visible = true
	char_location_label.visible = true

func _update_preview_renderer(char_data: Dictionary) -> void:
	if not _preview_renderer: return
	
	var body_id = char_data.get("body", 0)
	var head_id = char_data.get("head", 0)
	var weapon_id = char_data.get("weapon", 0)
	var shield_id = char_data.get("shield", 0)
	var helmet_id = char_data.get("helmet", 0)
	
	if body_id > 0: _preview_renderer.body = body_id
	if head_id > 0: _preview_renderer.head = head_id
	if weapon_id > 0: _preview_renderer.weapon = weapon_id
	if shield_id > 0: _preview_renderer.shield = shield_id
	if helmet_id > 0: _preview_renderer.helmet = helmet_id
	
	_preview_renderer.heading = Enums.Heading.South
	_preview_renderer.Play()
	_preview_renderer.visible = true

func _clear_character_info() -> void:
	char_name_label.text = ""
	char_details_label.text = ""
	char_location_label.text = ""
	if _preview_renderer:
		_preview_renderer.visible = false

func _on_connect_pressed() -> void:
	if selected_index >= 0 and selected_index < characters.size():
		var char_name = characters[selected_index].get("name", "")
		if not char_name.is_empty():
			character_selected.emit(char_name)

func _on_create_pressed() -> void:
	if characters.size() >= MAX_CHARACTERS:
		_show_error("Ya tienes el máximo de personajes permitidos")
		return
	
	# Cargar pantalla de creación de personaje directamente
	var screen = load("uid://bp35uafwebjdb").instantiate()
	ScreenController.SwitchScreen(screen)

func _on_delete_pressed() -> void:
	if selected_index < 0 or selected_index >= characters.size(): return
	
	var char_name = characters[selected_index].get("name", "")
	
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "¿Estás seguro de que deseas borrar a " + char_name + "?"
	confirm.title = "Confirmar borrado"
	confirm.ok_button_text = "Borrar"
	confirm.cancel_button_text = "Cancelar"
	confirm.confirmed.connect(func():
		delete_character_requested.emit(char_name)
		confirm.queue_free()
	)
	add_child(confirm)
	confirm.popup_centered()

func _on_logout_pressed() -> void:
	Global.account_name = ""
	Global.account_hash = ""
	ClientInterface.DisconnectFromHost()
	
	var login_screen = load("res://screens/login_screen.tscn").instantiate()
	ScreenController.SwitchScreen(login_screen)
	logout_requested.emit()

func _show_error(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Error"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())
