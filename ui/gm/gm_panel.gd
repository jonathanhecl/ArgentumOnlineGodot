extends Window
class_name GMPanel

# Panel de comandos GM para Argentum Online Godot
# Interfaz gráfica para ejecutar comandos de administración

@onready var category_tabs: TabContainer = $VBox/CategoryTabs
@onready var command_input: LineEdit = $VBox/CommandSection/HBox/CommandInput
@onready var execute_button: Button = $VBox/CommandSection/HBox/ExecuteButton
@onready var output_text: RichTextLabel = $VBox/OutputSection/OutputText
@onready var clear_button: Button = $VBox/OutputSection/HBox/ClearButton
@onready var history_button: Button = $VBox/OutputSection/HBox/HistoryButton

var gm_system: GMCommandSystem
var command_buttons: Dictionary = {}

signal command_executed(command: String)

func _ready():
	title = "Panel de Comandos GM - Argentum Online"
	size = Vector2(800, 600)
	
	# Conectar señales
	execute_button.pressed.connect(_on_execute_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	history_button.pressed.connect(_on_history_pressed)
	command_input.text_submitted.connect(_on_command_submitted)
	close_requested.connect(hide)
	
	# Obtener referencia al sistema GM
	gm_system = get_node("/root/GMCommandSystem")
	if gm_system:
		gm_system.command_executed.connect(_on_command_result)
	
	_setup_command_categories()
	_setup_autocomplete()

func _setup_command_categories():
	# Crear pestañas para cada categoría
	var categories = [
		{"name": "Mensajería", "category": GMCommandSystem.CommandCategory.MESSAGING},
		{"name": "Teletransporte", "category": GMCommandSystem.CommandCategory.TELEPORT_MOVEMENT},
		{"name": "Info Jugadores", "category": GMCommandSystem.CommandCategory.PLAYER_INFO},
		{"name": "Castigos", "category": GMCommandSystem.CommandCategory.PUNISHMENT},
		{"name": "Modificar PJ", "category": GMCommandSystem.CommandCategory.CHARACTER_MOD},
		{"name": "Control Servidor", "category": GMCommandSystem.CommandCategory.SERVER_CONTROL},
		{"name": "Mundo", "category": GMCommandSystem.CommandCategory.WORLD_MANIPULATION},
		{"name": "Audio/Visual", "category": GMCommandSystem.CommandCategory.AUDIO_VISUAL},
		{"name": "Facciones", "category": GMCommandSystem.CommandCategory.FACTION_MANAGEMENT},
		{"name": "Administrativo", "category": GMCommandSystem.CommandCategory.ADMINISTRATIVE}
	]
	
	for cat_info in categories:
		var tab = _create_category_tab(cat_info.name, cat_info.category)
		category_tabs.add_child(tab)

func _create_category_tab(tab_name: String, category: GMCommandSystem.CommandCategory) -> ScrollContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(vbox)
	
	# Obtener comandos de esta categoría
	if gm_system:
		var commands = gm_system.get_commands_by_category(category)
		
		for command in commands:
			var command_panel = _create_command_panel(command)
			vbox.add_child(command_panel)
	
	return scroll

func _create_command_panel(command: GMCommandSystem.GMCommand) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	# Información del comando
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Nombre del comando
	var name_label = Label.new()
	name_label.text = "/" + command.name.to_lower()
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.CYAN)
	info_vbox.add_child(name_label)
	
	# Descripción
	var desc_label = Label.new()
	desc_label.text = command.description
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	info_vbox.add_child(desc_label)
	
	# Uso
	var usage_label = Label.new()
	usage_label.text = "Uso: " + command.usage
	usage_label.add_theme_font_size_override("font_size", 10)
	usage_label.add_theme_color_override("font_color", Color.YELLOW)
	info_vbox.add_child(usage_label)
	
	# Botones de acción
	var button_vbox = VBoxContainer.new()
	hbox.add_child(button_vbox)
	
	# Botón ejecutar
	var exec_button = Button.new()
	exec_button.text = "Ejecutar"
	exec_button.custom_minimum_size = Vector2(80, 25)
	exec_button.pressed.connect(_on_command_button_pressed.bind(command))
	button_vbox.add_child(exec_button)
	
	# Botón copiar
	var copy_button = Button.new()
	copy_button.text = "Copiar"
	copy_button.custom_minimum_size = Vector2(80, 25)
	copy_button.pressed.connect(_on_copy_command.bind(command.usage))
	button_vbox.add_child(copy_button)
	
	# Marcar comandos de admin
	if command.admin_only:
		var admin_label = Label.new()
		admin_label.text = "[ADMIN]"
		admin_label.add_theme_color_override("font_color", Color.RED)
		admin_label.add_theme_font_size_override("font_size", 10)
		info_vbox.add_child(admin_label)
	
	return panel

func _setup_autocomplete():
	# Configurar autocompletado para el input de comandos
	command_input.placeholder_text = "Escriba un comando GM aquí... (ej: /gmsg Hola aventureros)"

func _on_execute_pressed():
	_execute_command()

func _on_command_submitted(text: String):
	_execute_command()

func _execute_command():
	var command_text = command_input.text.strip_edges()
	if command_text.is_empty():
		_add_output("Error: Comando vacío", Color.RED)
		return
	
	if not command_text.begins_with("/"):
		command_text = "/" + command_text
	
	_add_output("> " + command_text, Color.CYAN)
	
	if gm_system:
		var success = gm_system.execute_command(command_text)
		if not success:
			_add_output("Error: Comando no válido o sin permisos", Color.RED)
	else:
		_add_output("Error: Sistema GM no disponible", Color.RED)
	
	command_input.clear()

func _on_command_button_pressed(command: GMCommandSystem.GMCommand):
	if command.parameters.is_empty():
		# Ejecutar directamente si no requiere parámetros
		var cmd_text = "/" + command.name.to_lower()
		command_input.text = cmd_text
		_execute_command()
	else:
		# Mostrar diálogo para parámetros
		_show_parameter_dialog(command)

func _show_parameter_dialog(command: GMCommandSystem.GMCommand):
	var dialog = _create_parameter_dialog(command)
	add_child(dialog)
	dialog.popup_centered()

func _create_parameter_dialog(command: GMCommandSystem.GMCommand) -> AcceptDialog:
	var dialog = AcceptDialog.new()
	dialog.title = "Parámetros para " + command.name
	dialog.size = Vector2(400, 300)
	
	var vbox = VBoxContainer.new()
	dialog.add_child(vbox)
	
	# Descripción del comando
	var desc_label = Label.new()
	desc_label.text = command.description + "\n" + command.usage
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Campos para parámetros
	var param_inputs: Array[LineEdit] = []
	
	for i in range(command.parameters.size()):
		var param = command.parameters[i]
		var is_optional = param.begins_with("[") and param.ends_with("]")
		var param_name = param
		if is_optional:
			param_name = param_name.substr(1, param_name.length() - 2)  # Remover [ y ]
		param_name = param_name.strip_edges()
		
		var param_label = Label.new()
		param_label.text = param_name.capitalize() + (":" if not is_optional else " (opcional):")
		vbox.add_child(param_label)
		
		var param_input = LineEdit.new()
		param_input.placeholder_text = "Ingrese " + param_name
		vbox.add_child(param_input)
		param_inputs.append(param_input)
	
	# Botón ejecutar en el diálogo
	var exec_button = Button.new()
	exec_button.text = "Ejecutar Comando"
	vbox.add_child(exec_button)
	
	exec_button.pressed.connect(func():
		var cmd_parts = ["/" + command.name.to_lower()]
		
		for input in param_inputs:
			if not input.text.is_empty():
				cmd_parts.append(input.text)
		
		var full_command = " ".join(cmd_parts)
		command_input.text = full_command
		dialog.queue_free()
		_execute_command()
	)
	
	return dialog

func _on_copy_command(usage: String):
	DisplayServer.clipboard_set(usage)
	_add_output("Comando copiado al portapapeles: " + usage, Color.GREEN)

func _on_clear_pressed():
	output_text.clear()

func _on_history_pressed():
	_show_command_history()

func _show_command_history():
	if not gm_system:
		return
	
	var history = gm_system.get_command_history()
	if history.is_empty():
		_add_output("Historial vacío", Color.YELLOW)
		return
	
	_add_output("=== HISTORIAL DE COMANDOS ===", Color.CYAN)
	for i in range(history.size() - 1, max(0, history.size() - 10), -1):
		_add_output(str(i + 1) + ". " + history[i], Color.WHITE)

func _on_command_result(command: String, result: String):
	var color = Color.GREEN if not result.begins_with("Error") else Color.RED
	_add_output(result, color)

func _add_output(text: String, color: Color = Color.WHITE):
	output_text.append_text("[color=" + color.to_html() + "]" + text + "[/color]\n")
	
	# Auto-scroll al final
	await get_tree().process_frame
	output_text.scroll_to_line(output_text.get_line_count() - 1)

# Función para abrir el panel desde otros scripts
func show_panel():
	show()
	command_input.grab_focus()

# Filtrar comandos por texto
func filter_commands(search_text: String):
	# TODO: Implementar filtrado de comandos en las pestañas
	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		# Atajos de teclado
		if event.ctrl_pressed:
			match event.keycode:
				KEY_ENTER:
					_execute_command()
				KEY_L:
					_on_clear_pressed()
				KEY_H:
					_on_history_pressed()
