extends Window
class_name PlayerInfoWindow

# Ventana de información de jugador para comandos GM
# Muestra estadísticas, inventario, habilidades, etc.

@onready var tab_container: TabContainer = $VBox/TabContainer
@onready var player_name_label: Label = $VBox/HeaderSection/PlayerNameLabel
@onready var close_button: Button = $VBox/ButtonSection/CloseButton
@onready var refresh_button: Button = $VBox/ButtonSection/RefreshButton

# Tabs de información
@onready var general_tab: Control = $VBox/TabContainer/General
@onready var stats_tab: Control = $VBox/TabContainer/Estadísticas
@onready var inventory_tab: Control = $VBox/TabContainer/Inventario
@onready var skills_tab: Control = $VBox/TabContainer/Habilidades
@onready var bank_tab: Control = $VBox/TabContainer/Bóveda

# Controles de información general
@onready var general_info: RichTextLabel = $VBox/TabContainer/General/GeneralInfo
@onready var stats_info: RichTextLabel = $VBox/TabContainer/Estadísticas/StatsInfo
@onready var inventory_list: ItemList = $VBox/TabContainer/Inventario/InventoryList
@onready var skills_info: RichTextLabel = $VBox/TabContainer/Habilidades/SkillsInfo
@onready var bank_list: ItemList = $VBox/TabContainer/Bóveda/BankList

var current_player: String = ""
var player_data: Dictionary = {}

signal refresh_requested(player_name: String)

func _ready():
	title = "Información de Jugador - GM"
	size = Vector2(600, 500)
	
	close_button.pressed.connect(hide)
	refresh_button.pressed.connect(_on_refresh_pressed)
	close_requested.connect(hide)
	
	# Conectar con el sistema de protocolo
	var protocol = get_node("/root/GameProtocol")
	if protocol:
		protocol.message_received.connect(_on_protocol_message)

func show_player_info(player_name: String, info_type: String = "general"):
	current_player = player_name
	player_name_label.text = "Jugador: " + player_name
	
	# Limpiar información anterior
	_clear_all_info()
	
	# Solicitar información según el tipo
	match info_type:
		"general":
			Global.game_protocol.WriteRequestCharInfo(player_name)
			tab_container.current_tab = 0
		"stats":
			Global.game_protocol.WriteRequestCharStats(player_name)
			tab_container.current_tab = 1
		"inventory":
			Global.game_protocol.WriteRequestCharInventory(player_name)
			tab_container.current_tab = 2
		"skills":
			Global.game_protocol.WriteRequestCharSkills(player_name)
			tab_container.current_tab = 3
		"bank":
			Global.game_protocol.WriteRequestCharBank(player_name)
			tab_container.current_tab = 4
	
	show()

func _on_refresh_pressed():
	if not current_player.is_empty():
		var current_tab_index = tab_container.current_tab
		var info_types = ["general", "stats", "inventory", "skills", "bank"]
		show_player_info(current_player, info_types[current_tab_index])

func _on_protocol_message(message_type: String, data: Dictionary):
	if not visible or current_player.is_empty():
		return
	
	match message_type:
		"REQUEST_CHAR_INFO":
			_update_general_info(data)
		"REQUEST_CHAR_STATS":
			_update_stats_info(data)
		"REQUEST_CHAR_INVENTORY":
			_update_inventory_info(data)
		"REQUEST_CHAR_SKILLS":
			_update_skills_info(data)
		"REQUEST_CHAR_BANK":
			_update_bank_info(data)

func _update_general_info(data: Dictionary):
	var info_text = "[center][b]Información General[/b][/center]\n\n"
	
	if data.has("data") and not data.data.is_empty():
		var char_data = data.data
		info_text += "[b]Nombre:[/b] " + char_data.get("nick", "N/A") + "\n"
		info_text += "[b]Nivel:[/b] " + str(char_data.get("level", "N/A")) + "\n"
		info_text += "[b]Clase:[/b] " + char_data.get("class", "N/A") + "\n"
		info_text += "[b]Clan:[/b] " + char_data.get("guild", "Sin clan") + "\n"
		info_text += "[b]Estado:[/b] " + char_data.get("status", "N/A") + "\n"
		info_text += "[b]Ubicación:[/b] Mapa " + str(char_data.get("map", "N/A")) + "\n"
		info_text += "[b]Posición:[/b] (" + str(char_data.get("x", "N/A")) + ", " + str(char_data.get("y", "N/A")) + ")\n"
		info_text += "[b]Oro:[/b] " + str(char_data.get("gold", "N/A")) + "\n"
		info_text += "[b]Banco:[/b] " + str(char_data.get("bank_gold", "N/A")) + " monedas\n"
		
		if char_data.has("faction"):
			info_text += "[b]Facción:[/b] " + char_data.faction + "\n"
		
		if char_data.has("criminal_status"):
			info_text += "[b]Estado Criminal:[/b] " + char_data.criminal_status + "\n"
		
		if char_data.has("last_login"):
			info_text += "[b]Último Login:[/b] " + char_data.last_login + "\n"
	else:
		info_text += "[color=red]No se pudo obtener información del jugador[/color]"
	
	general_info.text = info_text

func _update_stats_info(data: Dictionary):
	var stats_text = "[center][b]Estadísticas del Personaje[/b][/center]\n\n"
	
	if data.has("data") and not data.data.is_empty():
		var char_stats = data.data
		
		# Atributos principales
		stats_text += "[b][color=cyan]Atributos Principales[/color][/b]\n"
		stats_text += "Fuerza: " + str(char_stats.get("strength", "N/A")) + "\n"
		stats_text += "Agilidad: " + str(char_stats.get("agility", "N/A")) + "\n"
		stats_text += "Inteligencia: " + str(char_stats.get("intelligence", "N/A")) + "\n"
		stats_text += "Carisma: " + str(char_stats.get("charisma", "N/A")) + "\n"
		stats_text += "Constitución: " + str(char_stats.get("constitution", "N/A")) + "\n\n"
		
		# Vida y Maná
		stats_text += "[b][color=red]Vida y Maná[/color][/b]\n"
		stats_text += "Vida: " + str(char_stats.get("hp", "N/A")) + "/" + str(char_stats.get("max_hp", "N/A")) + "\n"
		stats_text += "Maná: " + str(char_stats.get("mp", "N/A")) + "/" + str(char_stats.get("max_mp", "N/A")) + "\n"
		stats_text += "Stamina: " + str(char_stats.get("stamina", "N/A")) + "/" + str(char_stats.get("max_stamina", "N/A")) + "\n\n"
		
		# Experiencia
		stats_text += "[b][color=yellow]Experiencia[/color][/b]\n"
		stats_text += "Experiencia: " + str(char_stats.get("exp", "N/A")) + "\n"
		stats_text += "Siguiente Nivel: " + str(char_stats.get("exp_next", "N/A")) + "\n\n"
		
		# Combate
		stats_text += "[b][color=orange]Estadísticas de Combate[/color][/b]\n"
		stats_text += "Golpe Mínimo: " + str(char_stats.get("min_hit", "N/A")) + "\n"
		stats_text += "Golpe Máximo: " + str(char_stats.get("max_hit", "N/A")) + "\n"
		stats_text += "Defensa: " + str(char_stats.get("defense", "N/A")) + "\n"
	else:
		stats_text += "[color=red]No se pudieron obtener las estadísticas[/color]"
	
	stats_info.text = stats_text

func _update_inventory_info(data: Dictionary):
	inventory_list.clear()
	
	if data.has("data") and data.data.has("items"):
		var items = data.data.items
		
		for i in range(items.size()):
			var item = items[i]
			if item.has("name") and not item.name.is_empty():
				var item_text = str(i + 1) + ". " + item.name
				if item.has("quantity") and item.quantity > 1:
					item_text += " (x" + str(item.quantity) + ")"
				if item.has("equipped") and item.equipped:
					item_text += " [EQUIPADO]"
				
				inventory_list.add_item(item_text)
	else:
		inventory_list.add_item("No se pudo obtener el inventario")

func _update_skills_info(data: Dictionary):
	var skills_text = "[center][b]Habilidades del Personaje[/b][/center]\n\n"
	
	if data.has("data") and data.data.has("skills"):
		var skills = data.data.skills
		
		# Habilidades de combate
		skills_text += "[b][color=red]Combate[/color][/b]\n"
		skills_text += "Combate con Armas: " + str(skills.get("weapon_combat", "N/A")) + "\n"
		skills_text += "Combate sin Armas: " + str(skills.get("unarmed_combat", "N/A")) + "\n"
		skills_text += "Defensa con Escudos: " + str(skills.get("shield_defense", "N/A")) + "\n"
		skills_text += "Tiro Certero: " + str(skills.get("archery", "N/A")) + "\n\n"
		
		# Habilidades mágicas
		skills_text += "[b][color=blue]Magia[/color][/b]\n"
		skills_text += "Magia: " + str(skills.get("magic", "N/A")) + "\n"
		skills_text += "Resistencia Mágica: " + str(skills.get("magic_resistance", "N/A")) + "\n"
		skills_text += "Meditación: " + str(skills.get("meditation", "N/A")) + "\n\n"
		
		# Habilidades de supervivencia
		skills_text += "[b][color=green]Supervivencia[/color][/b]\n"
		skills_text += "Supervivencia: " + str(skills.get("survival", "N/A")) + "\n"
		skills_text += "Curar Heridas: " + str(skills.get("healing", "N/A")) + "\n"
		skills_text += "Ocultarse: " + str(skills.get("hiding", "N/A")) + "\n\n"
		
		# Habilidades de trabajo
		skills_text += "[b][color=brown]Trabajo[/color][/b]\n"
		skills_text += "Minería: " + str(skills.get("mining", "N/A")) + "\n"
		skills_text += "Talar Árboles: " + str(skills.get("lumberjacking", "N/A")) + "\n"
		skills_text += "Pesca: " + str(skills.get("fishing", "N/A")) + "\n"
		skills_text += "Herrería: " + str(skills.get("blacksmithing", "N/A")) + "\n"
		skills_text += "Carpintería: " + str(skills.get("carpentry", "N/A")) + "\n"
		
		# Puntos libres
		if skills.has("free_points"):
			skills_text += "\n[b][color=yellow]Puntos Libres: " + str(skills.free_points) + "[/color][/b]"
	else:
		skills_text += "[color=red]No se pudieron obtener las habilidades[/color]"
	
	skills_info.text = skills_text

func _update_bank_info(data: Dictionary):
	bank_list.clear()
	
	if data.has("data") and data.data.has("bank_items"):
		var items = data.data.bank_items
		
		for i in range(items.size()):
			var item = items[i]
			if item.has("name") and not item.name.is_empty():
				var item_text = str(i + 1) + ". " + item.name
				if item.has("quantity") and item.quantity > 1:
					item_text += " (x" + str(item.quantity) + ")"
				
				bank_list.add_item(item_text)
		
		# Mostrar oro del banco
		if data.data.has("bank_gold"):
			bank_list.add_item("--- ORO EN BANCO: " + str(data.data.bank_gold) + " ---")
	else:
		bank_list.add_item("No se pudo obtener información del banco")

func _clear_all_info():
	general_info.text = "Cargando información..."
	stats_info.text = "Cargando estadísticas..."
	inventory_list.clear()
	skills_info.text = "Cargando habilidades..."
	bank_list.clear()

# Función para mostrar información específica desde comandos GM
func show_char_info(nick: String):
	show_player_info(nick, "general")

func show_char_stats(nick: String):
	show_player_info(nick, "stats")

func show_char_inventory(nick: String):
	show_player_info(nick, "inventory")

func show_char_skills(nick: String):
	show_player_info(nick, "skills")

func show_char_bank(nick: String):
	show_player_info(nick, "bank")
