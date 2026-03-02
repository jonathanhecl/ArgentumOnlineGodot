extends Node
class_name GameScreen

# Cursor personalizado para selección de objetivo
var _crosshair_cursor: Texture2D = null
var _scaled_crosshair_cursor = null
@export var _gameInput:HubController
@export var _gameWorld:GameWorld
@export var _camera:Camera2D
@export var _rainOverlay: ColorRect

var _input:Dictionary[String, int] = {
	"ui_left" = Enums.Heading.West,
	"ui_right" = Enums.Heading.East,
	"ui_up" = Enums.Heading.North,
	"ui_down" = Enums.Heading.South,
}

var _is_raining: bool = false
var _player_velocity_y: float = 0.0  # Para efecto de lluvia relativo al movimiento

# Sistema de audio para lluvia
var _rain_start_player: AudioStreamPlayer = null
var _rain_loop_player: AudioStreamPlayer = null
var _rain_end_player: AudioStreamPlayer = null

# Sistema de fade para el shader de lluvia
var _rain_fade_tween: Tween = null

const _MAP_TILE_SIZE := 100
const _MAP_BORDER_THRESHOLD_TILES := 20

var _pending_map_transition_effect: bool = false
var _pending_map_id: int = -1
var _pending_map_name: String = ""
var _pending_map_zone: String = ""
var _last_known_x: int = -1
var _last_known_y: int = -1
var _pre_transition_map_x: int = -1
var _pre_transition_map_y: int = -1
var _map_transition_timer: Timer = null
var _map_transition_overlay: ColorRect = null
var _map_transition_tween: Tween = null

# Acceso al contexto global
var _gameContext: GameContext:
	get: return ProtocolHandler.game_context

var _mainCharacterInstanceId: int:
	get: return ProtocolHandler.main_character_id
	set(value): ProtocolHandler.main_character_id = value
 
func _ready() -> void: 
	ClientInterface.disconnected.connect(_OnDisconnected)
	
	# Registrar referencias globales para el ProtocolHandler
	ProtocolHandler.game_world = _gameWorld
	ProtocolHandler.hub_controller = _gameInput
	
	# Conectar señales del ProtocolHandler
	_connect_protocol_signals()
	
	_gameInput.Init(_gameContext)
	_gameInput.update_name_label(Global.username)
	
	# Cargar el cursor después de que los recursos estén listos
	if FileAccess.file_exists("res://Assets/Cursors/crosshair.png"):
		_crosshair_cursor = load("res://Assets/Cursors/crosshair.png")
		if _crosshair_cursor:
			_scaled_crosshair_cursor = _scale_cursor(_crosshair_cursor, 0.5)
	
	if _rainOverlay:
		_rainOverlay.visible = _is_raining

	_setup_map_transition_timer()
	_setup_map_transition_overlay()

func _exit_tree() -> void:
	# Limpiar referencias globales
	ProtocolHandler.game_world = null
	ProtocolHandler.hub_controller = null
	
	# Desconectar señales al salir para evitar llamadas a nodos destruidos
	if ClientInterface.disconnected.is_connected(_OnDisconnected):
		ClientInterface.disconnected.disconnect(_OnDisconnected)
	
	_disconnect_protocol_signals()

	if _map_transition_overlay:
		_map_transition_overlay.queue_free()
		_map_transition_overlay = null
		
	if _map_transition_timer:
		_map_transition_timer.queue_free()
		_map_transition_timer = null

# Función para escalar el cursor a un tamaño más pequeño
func _scale_cursor(texture: Texture2D, scale_factor: float) -> Texture2D:
	# Obtener la imagen del cursor
	var image = texture.get_image()
	
	# Calcular el nuevo tamaño
	var original_size = image.get_size()
	var new_size = original_size * scale_factor
	
	# Redimensionar la imagen
	image.resize(int(new_size.x), int(new_size.y), Image.INTERPOLATE_BILINEAR)
	
	# Crear una nueva textura con la imagen redimensionada
	var new_texture = ImageTexture.create_from_image(image)
	
	return new_texture
	 
func _OnDisconnected() -> void:
	print("[GameScreen] Desconectado del servidor, volviendo a login...")
	Security.reset_redundance()
	var screen = load("uid://cd452cndcck7v").instantiate() 
	ScreenController.SwitchScreen(screen)

func _process(_delta: float) -> void:
	_CheckKeys()
	_UpdateCameraPosition()
	_FlushData()
	
func _UpdateCameraPosition() -> void:
	var character = _gameWorld.GetCharacter(_mainCharacterInstanceId)
	if character && _camera:
		_camera.position = character.position
		_update_rain_world_offset(character.position)

func _CheckKeys() -> void:
	if _gameContext.traveling || _gameContext.mirandoForo ||\
		_gameContext.trading  || _gameContext.pause:
		return
	
	for k in _input:
		if Input.is_action_pressed(k):
			_MovePlayer(_input[k])
			return

func _MovePlayer(heading:int) -> void:
	if heading == Enums.Heading.None:
		return

	var character = _gameWorld.GetCharacter(_mainCharacterInstanceId)
	if character == null || character.isMoving:
		return
	
	# Actualizar posición conocida antes del movimiento
	_last_known_x = character.gridPosition.x
	_last_known_y = character.gridPosition.y
	
	# Actualizar velocidad vertical para efecto de lluvia
	# Norte (arriba) = con la lluvia = gotas más lentas (valor positivo)
	# Sur (abajo) = contra la lluvia = gotas más rápidas (valor negativo)
	if heading == Enums.Heading.North:
		_player_velocity_y = 1.0
	elif heading == Enums.Heading.South:
		_player_velocity_y = -1.0
		
	var newGridLocation = character.gridPosition + Vector2i(Utils.HeadingToVector(heading))
	if _CanMoveTo(newGridLocation.x, newGridLocation.y) && !_gameContext.userParalizado:
		#TODO 
		#No se porque esto esta asi. Lo unico que logra es que el personaje pegue un salto cuando camina
		#Obligando al usuario a presionar la tecla L(PosUpdate)
		GameProtocol.WriteWalk(heading)
		if !_gameContext.userDescansar && !_gameContext.userMeditar:
			_gameWorld.MoveCharacter(_mainCharacterInstanceId, heading)
	else:
		if character.renderer.heading != heading:
			GameProtocol.WriteChangeHeading(heading)
			character.renderer.heading = heading
			character.renderer.Stop()
	
	_gameInput.minimap.update_player_position(character.gridPosition.x, character.gridPosition.y)
	
	_last_known_x = character.gridPosition.x
	_last_known_y = character.gridPosition.y
	 
func _CanMoveTo(x:int, y:int) -> bool:
	var map = _gameWorld.GetMapContainer()
	
	#Tile Bloqueado?
	if map.GetTile(x - 1, y - 1) & Enums.TileState.Blocked:
		return false
	
	var character = map.GetCharacterAt(x, y)
	var mainCharacter = map.GetCharacter(_mainCharacterInstanceId)
	var playerPos = Vector2i(mainCharacter.gridPosition)
	
	if character:
		if map.GetTile(playerPos.x - 1, playerPos.y - 1) & Enums.TileState.Blocked:
			return false
			
		#Si no es casper, no puede pasar
		if character.renderer.head != Consts.CabezaCasper && character.renderer.body != Consts.CuerpoFragataFantasmal:
			return false
		else:
			#No puedo intercambiar con un casper que este en la orilla (Lado tierra)
			if map.GetTile(playerPos.x - 1, playerPos.y - 1) & Enums.TileState.Water:
				if !bool(map.GetTile(x - 1, y -1) & Enums.TileState.Water):
					return false
			else:
				#No puedo intercambiar con un casper que este en la orilla (Lado agua)
				if map.GetTile(x - 1, y -1) & Enums.TileState.Water:
					return false
			#Los admins no pueden intercambiar pos con caspers cuando estan invisibles
			if mainCharacter.priv > 0 && mainCharacter.priv < 6:
				if mainCharacter.GetCharacterInvisible():
					return false
		 
	if _gameContext.userNavegando != bool(map.GetTile(x - 1, y -1) & Enums.TileState.Water):
		return false
	
	return true

#region Protocol Signal Connections

func _connect_protocol_signals() -> void:
	# Character signals
	ProtocolHandler.character_created.connect(_on_character_created)
	ProtocolHandler.character_removed.connect(_on_character_removed)
	ProtocolHandler.character_moved.connect(_on_character_moved)
	ProtocolHandler.character_changed.connect(_on_character_changed)
	ProtocolHandler.character_change_nick.connect(_on_character_change_nick)
	ProtocolHandler.character_heading_changed.connect(_on_character_heading_changed)
	ProtocolHandler.user_char_index_received.connect(_on_user_char_index)
	ProtocolHandler.set_invisible.connect(_on_set_invisible)
	ProtocolHandler.fx_created.connect(_on_fx_created)
	ProtocolHandler.update_tag_and_status.connect(_on_update_tag_status)
	ProtocolHandler.chat_over_head.connect(_on_chat_over_head)
	ProtocolHandler.remove_char_dialog.connect(_on_remove_char_dialog)
	ProtocolHandler.remove_all_dialogs.connect(_on_remove_all_dialogs)
	
	# Map signals
	ProtocolHandler.map_changed.connect(_on_map_changed)
	ProtocolHandler.pos_updated.connect(_on_pos_updated)
	ProtocolHandler.force_char_move.connect(_on_force_char_move)
	ProtocolHandler.object_created.connect(_on_object_created)
	ProtocolHandler.object_deleted.connect(_on_object_deleted)
	ProtocolHandler.block_position_changed.connect(_on_block_position)
	
	# Inventory signals  
	ProtocolHandler.inventory_slot_changed.connect(_on_inventory_slot_changed)
	ProtocolHandler.spell_slot_changed.connect(_on_spell_slot_changed)
	ProtocolHandler.bank_slot_changed.connect(_on_bank_slot_changed)
	ProtocolHandler.npc_inventory_slot_changed.connect(_on_npc_inventory_slot_changed)
	
	# Stats signals
	ProtocolHandler.stats_updated.connect(_on_stats_updated)
	ProtocolHandler.hp_updated.connect(_on_hp_updated)
	ProtocolHandler.mana_updated.connect(_on_mana_updated)
	ProtocolHandler.stamina_updated.connect(_on_stamina_updated)
	ProtocolHandler.gold_updated.connect(_on_gold_updated)
	ProtocolHandler.exp_updated.connect(_on_exp_updated)
	ProtocolHandler.strength_updated.connect(_on_strength_updated)
	ProtocolHandler.dexterity_updated.connect(_on_dexterity_updated)
	ProtocolHandler.strength_dexterity_updated.connect(_on_strength_dexterity_updated)
	ProtocolHandler.hunger_thirst_updated.connect(_on_hunger_thirst_updated)
	ProtocolHandler.bank_gold_updated.connect(_on_bank_gold_updated)
	ProtocolHandler.attributes_received.connect(_on_attributes_received)
	ProtocolHandler.skills_received.connect(_on_skills_received)
	ProtocolHandler.fame_received.connect(_on_fame_received)
	ProtocolHandler.mini_stats_received.connect(_on_mini_stats_received)
	
	# Console/Chat signals
	ProtocolHandler.console_message.connect(_on_console_message)
	ProtocolHandler.show_message_box.connect(_on_show_message_box)
	ProtocolHandler.damage_created.connect(_on_damage_created)
	
	# Commerce signals
	ProtocolHandler.commerce_init.connect(_on_commerce_init)
	ProtocolHandler.commerce_end.connect(_on_commerce_end)
	ProtocolHandler.bank_init.connect(_on_bank_init)
	ProtocolHandler.bank_end.connect(_on_bank_end)
	ProtocolHandler.bank_gold_updated.connect(_on_bank_gold_updated)
	
	# Status toggles
	ProtocolHandler.stop_working.connect(_on_stop_working)
	ProtocolHandler.pong_received.connect(_on_pong_received)
	ProtocolHandler.rain_toggle.connect(_on_rain_toggle)
	
	# Guild signals
	ProtocolHandler.show_guild_align.connect(_on_show_guild_align)
	ProtocolHandler.show_guild_fundation_form.connect(_on_show_guild_fundation_form)
	ProtocolHandler.guild_list_received.connect(_on_guild_list)
	ProtocolHandler.guild_member_info_received.connect(_on_guild_member_info)
	ProtocolHandler.guild_leader_info_received.connect(_on_guild_leader_info)
	ProtocolHandler.guild_details_received.connect(_on_guild_details)
	ProtocolHandler.guild_news_received.connect(_on_guild_news)
	ProtocolHandler.offer_details_received.connect(_on_offer_details)
	ProtocolHandler.alliance_proposals_received.connect(_on_alliance_proposals)
	ProtocolHandler.peace_proposals_received.connect(_on_peace_proposals)
	
	# Trainer signals
	ProtocolHandler.trainer_creature_list_received.connect(_on_trainer_creature_list)
	
	# Multi-message signal
	ProtocolHandler.multi_message_received.connect(_on_multi_message)
	ProtocolHandler.work_request_target.connect(_on_work_request_target)

func _disconnect_protocol_signals() -> void:
	# Desconectar todas las señales del ProtocolHandler
	var signals_to_disconnect = [
		"character_created", "character_removed", "character_moved", "character_changed",
		"character_change_nick", "character_heading_changed", "user_char_index_received", "set_invisible", "fx_created",
		"update_tag_and_status", "chat_over_head", "remove_char_dialog", "remove_all_dialogs",
		"map_changed", "pos_updated", "force_char_move", "object_created", "object_deleted",
		"block_position_changed", "inventory_slot_changed", "spell_slot_changed",
		"bank_slot_changed", "npc_inventory_slot_changed", "stats_updated", "hp_updated",
		"mana_updated", "stamina_updated", "gold_updated", "exp_updated", "strength_updated",
		"dexterity_updated", "strength_dexterity_updated", "hunger_thirst_updated",
		"bank_gold_updated", "attributes_received", "skills_received", "fame_received",
		"mini_stats_received", "console_message", "show_message_box", "commerce_init",
		"commerce_end", "bank_init", "bank_end", "stop_working", "pong_received",
		"show_guild_align", "show_guild_fundation_form", "guild_list_received",
		"guild_member_info_received", "guild_leader_info_received", "guild_details_received",
		"guild_news_received", "offer_details_received", "alliance_proposals_received",
		"peace_proposals_received", "trainer_creature_list_received", "multi_message_received",
		"work_request_target", "damage_created", "rain_toggle"
	]
	for signal_name in signals_to_disconnect:
		if ProtocolHandler.has_signal(signal_name):
			var connections = ProtocolHandler.get_signal_connection_list(signal_name)
			for conn in connections:
				if conn["callable"].get_object() == self:
					ProtocolHandler.disconnect(signal_name, conn["callable"])

#endregion

#region Protocol Signal Handlers - Character

func _on_character_created(data: CharacterCreate) -> void:
	_gameWorld.CreateCharacter(data)
	
	if data.charIndex == _mainCharacterInstanceId:
		_check_and_play_map_transition(data.x, data.y)

func _on_character_removed(char_index: int) -> void:
	_gameWorld.DeleteCharacter(char_index)

func _on_character_moved(char_index: int, x: int, y: int) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character == null:
		return
	var addX = x - character.gridPosition.x
	var addY = y - character.gridPosition.y
	if addX == 0 and addY == 0:
		return
	var heading = Enums.Heading.South
	if Utils.Sgn(addX) == 1:
		heading = Enums.Heading.East
	elif Utils.Sgn(addX) == -1:
		heading = Enums.Heading.West
	elif Utils.Sgn(addY) == 1:
		heading = Enums.Heading.South
	elif Utils.Sgn(addY) == -1:
		heading = Enums.Heading.North
	_gameWorld.MoveCharacter(char_index, heading)

func _on_character_changed(data: CharacterChange) -> void:
	var character = _gameWorld.GetCharacter(data.charIndex)
	if character == null: return
	character.renderer.body = data.body
	character.renderer.head = data.head
	character.renderer.helmet = data.helmet
	character.renderer.weapon = data.weapon
	character.renderer.shield = data.shield

func _on_character_change_nick(char_index: int, char_name: String) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.SetCharacterName(char_name)

func _on_character_heading_changed(char_index: int, heading: int) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.renderer.heading = heading
		if character.isMoving:
			character.renderer.Play()
		else:
			character.renderer.Stop()

func _on_user_char_index(char_index: int) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.SetAsPlayer(true)
		_gameInput.minimap.update_player_position(character.gridPosition.x, character.gridPosition.y)

func _on_set_invisible(char_index: int, invisible: bool) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.SetCharacterInvisible(not invisible)

func _on_fx_created(char_index: int, fx: int, loops: int) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.effect.play_effect(fx, loops)

func _on_update_tag_status(char_index: int, tag: String, nick_color: int) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.SetCharacterName(tag)
		character.SetCharacterNameColor(Utils.GetNickColor(nick_color, character.priv))

func _on_chat_over_head(char_index: int, message: String, color: Color) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.Say(message, color)

func _on_remove_char_dialog(char_index: int) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.Say("", Color.WHITE)

func _on_remove_all_dialogs() -> void:
	pass

#endregion

#region Protocol Signal Handlers - Map

func _on_map_changed(map_id: int, name_map: String, zone: String) -> void:
	print("🌍 GameScreen: ¡Se recibió señal de cambio de mapa! Mapa ID: ", map_id, " Nombre: ", name_map, " Zona: ", zone)
	
	# Usar la última posición conocida en vez de consultar al personaje (que ya pudo ser borrado por el servidor)
	_pre_transition_map_x = _last_known_x
	_pre_transition_map_y = _last_known_y
		
	_pending_map_transition_effect = true
	_pending_map_id = map_id
	_pending_map_name = name_map
	_pending_map_zone = zone
	
	if _map_transition_timer:
		_map_transition_timer.start(1.5)
		
	_gameWorld.SwitchMap(map_id)
	_gameInput.minimap.load_thumbnail(map_id)

func _on_pos_updated(x: int, y: int) -> void:
	var target_position = Vector2((x - 1) * 32, (y - 1) * 32) + Vector2(16, 32)
	var character = _gameWorld.GetCharacter(_mainCharacterInstanceId)
	if character:
		character.StopMoving()
		character.gridPosition = Vector2i(x, y)
		character.position = target_position
		_gameInput.minimap.update_player_position(x, y)
		_last_known_x = x
		_last_known_y = y

	_check_and_play_map_transition(x, y)

func _check_and_play_map_transition(x: int, y: int) -> void:
	if _pending_map_transition_effect:
		_pending_map_transition_effect = false
		if _map_transition_timer:
			_map_transition_timer.stop()
			
		var transition_info = _get_map_transition_info(x, y)
		var transition_type = transition_info["type"]
		var reason = transition_info["reason"]
		
		_report_map_transition(transition_type, reason, x, y)
		
		# Asegurarse que el personaje existe antes de transicionar borde
		var character = _gameWorld.GetCharacter(_mainCharacterInstanceId)
		
		if transition_type == "INTERIOR_FADE" or transition_type == "UNKNOWN":
			_play_non_border_map_transition_effect(transition_type)
		elif character != null:
			_play_border_map_transition(character, transition_type, x, y)
		else:
			print("[MAP TRANSITION] Advertencia: Personaje no encontrado para transición de borde.")

func _on_force_char_move(heading: int) -> void:
	var character = _gameWorld.GetCharacter(_mainCharacterInstanceId)
	if character:
		character.StopMoving()
		_gameWorld.MoveCharacter(_mainCharacterInstanceId, heading)

func _on_object_created(grh_id: int, x: int, y: int) -> void:
	_gameWorld.AddObject(grh_id, x, y)

func _on_object_deleted(x: int, y: int) -> void:
	_gameWorld.DeleteObject(x, y)

func _on_block_position(x: int, y: int, blocked: bool) -> void:
	if blocked:
		_gameWorld.GetMapContainer().BlockTile(x - 1, y - 1)
	else:
		_gameWorld.GetMapContainer().UnblockTile(x - 1, y - 1)

func _on_rain_toggle() -> void:
	# No activar lluvia en mapas tipo dungeon/cueva
	if _is_current_map_a_dungeon():
		if not _is_raining:
			# Si intentan activar lluvia en dungeon, mostrar mensaje y no hacer nada
			print("[RAIN] Lluvia bloqueada: estás en un dungeon/interior (", _pending_map_zone, ")")
			return
		else:
			# Si está lloviendo y entramos a dungeon, detener la lluvia
			_is_raining = false
			_gameInput.ShowConsoleMessage("Has entrado a un lugar cubierto. La lluvia cesa.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
			_stop_rain_sound_sequence()
			_fade_out_rain()
			return
	
	_is_raining = not _is_raining
	
	if _is_raining:
		_gameInput.ShowConsoleMessage("Está lloviendo.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		_start_rain_sound_sequence()
		_fade_in_rain()
	else:
		_gameInput.ShowConsoleMessage("Ha dejado de llover.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		_stop_rain_sound_sequence()
		_fade_out_rain()

func _is_current_map_a_dungeon() -> bool:
	"""Verifica si el mapa actual es un dungeon/cueva/interior donde no llueve"""
	var zone_lower = _pending_map_zone.to_lower()
	
	# Lista de palabras clave que indican mapas interiores/dungeons
	var dungeon_keywords = [
		"dungeon", "cueva", "catacumba", "cripta", "mazmorra", 
		"interior", "casa", "tienda", "castillo", "fortaleza",
		"templo", "gruta", "caverna", "mina", "túnel", "tunnel",
		"sótano", "sotano", "bodega", "cellar", "cave"
	]
	
	for keyword in dungeon_keywords:
		if zone_lower.contains(keyword):
			return true
	
	return false

func _setup_map_transition_timer() -> void:
	if _map_transition_timer:
		return
		
	_map_transition_timer = Timer.new()
	_map_transition_timer.one_shot = true
	_map_transition_timer.timeout.connect(_on_map_transition_timeout)
	add_child(_map_transition_timer)

func _on_map_transition_timeout() -> void:
	if _pending_map_transition_effect:
		_pending_map_transition_effect = false
		print("[MAP TRANSITION] Timeout esperado posición! Ejecutando fade default.")
		if _gameInput:
			_gameInput.ShowConsoleMessage("[MAP TRANSITION] Timeout. Usando fade de emergencia.", FontData.new(Color.RED))
		_play_non_border_map_transition_effect("TIMEOUT")

func _setup_map_transition_overlay() -> void:
	if _map_transition_overlay:
		return

	_map_transition_overlay = ColorRect.new()
	_map_transition_overlay.name = "MapTransitionOverlay"
	_map_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_transition_overlay.color = Color(1, 1, 1, 1) # El shader define el color real
	_map_transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://shaders/iris_transition.gdshader")
	shader_material.set_shader_parameter("progress", 0.0)
	shader_material.set_shader_parameter("color", Color(0, 0, 0, 1.0))
	_map_transition_overlay.material = shader_material
	
	# Agregar el overlay directamente al viewport container para que tape solo el render del mapa
	var viewport_container = _gameInput.get_node("MainViewportContainer")
	if viewport_container:
		viewport_container.add_child(_map_transition_overlay)
	else:
		add_child(_map_transition_overlay)

func _is_interior_map_transition_position(x: int, y: int) -> bool:
	var interior_min = _MAP_BORDER_THRESHOLD_TILES + 1
	var interior_max = _MAP_TILE_SIZE - _MAP_BORDER_THRESHOLD_TILES
	return x >= interior_min \
		and x <= interior_max \
		and y >= interior_min \
		and y <= interior_max

func _get_map_transition_info(x: int, y: int) -> Dictionary:
	var info = { "type": "INTERIOR_FADE", "reason": "" }

	# Si no tenemos posición anterior, es un teleport de entrada al juego o reconexión
	if _pre_transition_map_x == -1 or _pre_transition_map_y == -1:
		info["reason"] = "Sin posición anterior (_pre_x/y = -1). Teleport o primera entrada."
		return info

	var prev_x = _pre_transition_map_x
	var prev_y = _pre_transition_map_y
	var max_edge = _MAP_TILE_SIZE - _MAP_BORDER_THRESHOLD_TILES
	
	# Comprobamos si el salto de coordenadas corresponde a cruzar un borde caminando.
	var walked_east = prev_x >= max_edge and x <= _MAP_BORDER_THRESHOLD_TILES
	var walked_west = prev_x <= _MAP_BORDER_THRESHOLD_TILES and x >= max_edge
	var walked_south = prev_y >= max_edge and y <= _MAP_BORDER_THRESHOLD_TILES
	var walked_north = prev_y <= _MAP_BORDER_THRESHOLD_TILES and y >= max_edge

	if walked_east:
		info["type"] = "BORDER_LEFT"
		info["reason"] = "Cruce contiguo ESTE (prev_x:%d >= %d -> x:%d <= %d)" % [prev_x, max_edge, x, _MAP_BORDER_THRESHOLD_TILES]
		return info
	if walked_west:
		info["type"] = "BORDER_RIGHT"
		info["reason"] = "Cruce contiguo OESTE (prev_x:%d <= %d -> x:%d >= %d)" % [prev_x, _MAP_BORDER_THRESHOLD_TILES, x, max_edge]
		return info
	if walked_south:
		info["type"] = "BORDER_TOP"
		info["reason"] = "Cruce contiguo SUR (prev_y:%d >= %d -> y:%d <= %d)" % [prev_y, max_edge, y, _MAP_BORDER_THRESHOLD_TILES]
		return info
	if walked_north:
		info["type"] = "BORDER_BOTTOM"
		info["reason"] = "Cruce contiguo NORTE (prev_y:%d <= %d -> y:%d >= %d)" % [prev_y, _MAP_BORDER_THRESHOLD_TILES, y, max_edge]
		return info

	# Si las posiciones no corresponden a un paso de mapa contiguo
	info["reason"] = "Teleport/Cueva detectado. Salto de prev(%d,%d) a nueva(%d,%d) no cumple criterio contiguo (Threshold: %d)" % [prev_x, prev_y, x, y, _MAP_BORDER_THRESHOLD_TILES]
	return info

func _report_map_transition(transition_type: String, reason: String, x: int, y: int) -> void:
	var message = "[MAP TRANSITION] type=%s map=%d (%s) pos=(%d,%d)\n-> %s" % [
		transition_type,
		_pending_map_id,
		_pending_map_name,
		x,
		y,
		reason
	]
	print("==================================================")
	print(message)
	print("==================================================")
	if _gameInput:
		_gameInput.ShowConsoleMessage(message, GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])

func _play_border_map_transition(character: Character, transition_type: String, x: int, y: int) -> void:
	# Nos aseguramos de forzar stop y reset de estados
	character.StopMoving()
	
	var heading = _get_border_transition_heading(transition_type)
	if heading == Enums.Heading.None:
		return

	var target_position = Vector2((x - 1) * 32, (y - 1) * 32) + Vector2(16, 32)
	var heading_vector = Vector2(Utils.HeadingToVector(heading))
	character.position = target_position - (heading_vector * Consts.TileSize)
	character.gridPosition = Vector2i(x, y)
	character.renderer.heading = heading
	
	# Ocultamos capa por 1 frame para evitar parpadeos y luego lo deslizamos
	character.visible = false
	get_tree().create_timer(0.05).timeout.connect(func():
		if is_instance_valid(character):
			character.visible = true
	)
	character.MoveTo(heading)

func _get_border_transition_heading(transition_type: String) -> int:
	match transition_type:
		"BORDER_LEFT":
			return Enums.Heading.East
		"BORDER_RIGHT":
			return Enums.Heading.West
		"BORDER_TOP":
			return Enums.Heading.South
		"BORDER_BOTTOM":
			return Enums.Heading.North
		_:
			return Enums.Heading.None

func _play_non_border_map_transition_effect(_reason: String = "") -> void:
	if not _map_transition_overlay:
		return

	if _map_transition_tween and _map_transition_tween.is_valid():
		_map_transition_tween.kill()

	# Arranca cerrado (pantalla negra) para ocultar el destello/creación de red
	_map_transition_overlay.material.set_shader_parameter("progress", 1.0)
	
	_map_transition_tween = create_tween()
	# Mantiene cerrado un instante muy corto
	_map_transition_tween.tween_interval(0.15)
	
	# Abre el iris rápidamente hacia los bordes
	_map_transition_tween.tween_method(
		func(val): _map_transition_overlay.material.set_shader_parameter("progress", val), 
		1.0, 
		0.0, 
		0.45
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _fade_in_rain() -> void:
	if not _rainOverlay:
		return
	
	_rainOverlay.visible = true
	
	# Cancelar cualquier fade anterior
	if _rain_fade_tween and _rain_fade_tween.is_valid():
		_rain_fade_tween.kill()
	
	# Iniciar opacidad en 0 y hacer fade in
	if _rainOverlay.material:
		_rainOverlay.material.set_shader_parameter("rain_opacity", 0.0)
	
	# El fade in dura ~1.5 segundos (coincide con el sonido de inicio)
	_rain_fade_tween = create_tween()
	_rain_fade_tween.tween_method(_set_rain_opacity, 0.0, 1.0, 1.5)

func _fade_out_rain() -> void:
	if not _rainOverlay:
		return
	
	# Cancelar cualquier fade anterior
	if _rain_fade_tween and _rain_fade_tween.is_valid():
		_rain_fade_tween.kill()
	
	# El fade out dura ~2 segundos (coincide con el sonido de fin)
	_rain_fade_tween = create_tween()
	_rain_fade_tween.tween_method(_set_rain_opacity, 1.0, 0.0, 2.0)
	_rain_fade_tween.finished.connect(_on_rain_fade_out_finished)

func _set_rain_opacity(opacity: float) -> void:
	if _rainOverlay and _rainOverlay.material:
		_rainOverlay.material.set_shader_parameter("rain_opacity", opacity)

func _on_rain_fade_out_finished() -> void:
	_rainOverlay.visible = false

func _start_rain_sound_sequence() -> void:
	# Detener cualquier audio de lluvia anterior
	_stop_all_rain_sounds()
	
	# 1. Reproducir sonido de inicio
	if ResourceLoader.exists("res://Assets/Sfx/lluviaoutst.wav"):
		_rain_start_player = AudioStreamPlayer.new()
		add_child(_rain_start_player)
		_rain_start_player.stream = load("res://Assets/Sfx/lluviaoutst.wav")
		_rain_start_player.bus = "sfx"
		
		# Conectar para reproducir el loop cuando termine el start
		_rain_start_player.finished.connect(_on_rain_start_finished)
		_rain_start_player.play()
	else:
		# Si no existe el start, ir directamente al loop
		_start_rain_loop()

func _on_rain_start_finished() -> void:
	# Limpiar el player de inicio
	if _rain_start_player:
		_rain_start_player.queue_free()
		_rain_start_player = null
	# Iniciar el loop
	_start_rain_loop()

func _start_rain_loop() -> void:
	if ResourceLoader.exists("res://Assets/Sfx/lluviaout.wav"):
		_rain_loop_player = AudioStreamPlayer.new()
		add_child(_rain_loop_player)
		var stream = load("res://Assets/Sfx/lluviaout.wav") as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.mix_rate * int(stream.get_length())
		_rain_loop_player.stream = stream
		_rain_loop_player.bus = "sfx"
		_rain_loop_player.play()

func _stop_rain_sound_sequence() -> void:
	# Detener el loop
	if _rain_loop_player:
		_rain_loop_player.stop()
		_rain_loop_player.queue_free()
		_rain_loop_player = null
	
	# Reproducir sonido de fin
	if ResourceLoader.exists("res://Assets/Sfx/lluviaoutend.wav"):
		_rain_end_player = AudioStreamPlayer.new()
		add_child(_rain_end_player)
		_rain_end_player.stream = load("res://Assets/Sfx/lluviaoutend.wav")
		_rain_end_player.bus = "sfx"
		_rain_end_player.finished.connect(_on_rain_end_finished)
		_rain_end_player.play()

func _on_rain_end_finished() -> void:
	if _rain_end_player:
		_rain_end_player.queue_free()
		_rain_end_player = null

func _stop_all_rain_sounds() -> void:
	if _rain_start_player:
		if _rain_start_player.is_playing():
			_rain_start_player.stop()
		_rain_start_player.queue_free()
		_rain_start_player = null
	
	if _rain_loop_player:
		if _rain_loop_player.is_playing():
			_rain_loop_player.stop()
		_rain_loop_player.queue_free()
		_rain_loop_player = null
	
	if _rain_end_player:
		if _rain_end_player.is_playing():
			_rain_end_player.stop()
		_rain_end_player.queue_free()
		_rain_end_player = null

func _update_rain_world_offset(camera_pos: Vector2) -> void:
	if _rainOverlay and _rainOverlay.material:
		_rainOverlay.material.set_shader_parameter("world_offset", camera_pos)
		_rainOverlay.material.set_shader_parameter("player_velocity_y", _player_velocity_y)
		# Suavizar la velocidad hacia 0 cuando no se mueve
		_player_velocity_y = lerp(_player_velocity_y, 0.0, 0.15)

#endregion

#region Protocol Signal Handlers - Inventory

func _on_inventory_slot_changed(slot: int, item_stack: ItemStack) -> void:
	_gameInput.update_equipment_label(slot, item_stack)

func _on_spell_slot_changed(slot: int, spell_name: String) -> void:
	_gameInput.spell_list_panel.set_slot_text(slot, spell_name)

func _on_bank_slot_changed(_slot: int, _item_stack: ItemStack) -> void:
	pass # Bank UI updates handled by bank_panel

func _on_npc_inventory_slot_changed(_slot: int, _item_stack: ItemStack) -> void:
	pass # Merchant UI updates handled by merchant panel

#endregion

#region Protocol Signal Handlers - Stats

func _on_stats_updated(p: UpdateUserStats) -> void:
	_gameInput.update_gold_label(p.gold)
	_gameInput.update_level_label(p.elv)
	_gameInput.experience_stat_bar.max_value = p.elu
	_gameInput.experience_stat_bar.value = p.experience
	_gameInput.health_stat_bar.max_value = p.maxHp
	_gameInput.health_stat_bar.value = p.minHp
	_gameInput.mana_stat_bar.max_value = p.maxMana
	_gameInput.mana_stat_bar.value = p.minMana
	_gameInput.stamina_stat_bar.max_value = p.maxSta
	_gameInput.stamina_stat_bar.value = p.minSta

func _on_hp_updated(hp: int) -> void:
	_gameInput.health_stat_bar.value = hp

func _on_mana_updated(mana: int) -> void:
	_gameInput.mana_stat_bar.value = mana

func _on_stamina_updated(sta: int) -> void:
	_gameInput.stamina_stat_bar.value = sta

func _on_gold_updated(gold: int) -> void:
	_gameInput.update_gold_label(gold)

func _on_exp_updated(exp: int) -> void:
	_gameInput.experience_stat_bar.value = exp

func _on_strength_updated(value: int) -> void:
	_gameInput.update_strength_label(value)

func _on_dexterity_updated(value: int) -> void:
	_gameInput.update_agility_label(value)

func _on_strength_dexterity_updated(strength: int, dexterity: int) -> void:
	_gameInput.update_strength_label(strength)
	_gameInput.update_agility_label(dexterity)

func _on_hunger_thirst_updated(min_ham: int, max_ham: int, min_agua: int, max_agua: int) -> void:
	_gameInput.hunger_stat_bar.max_value = max_ham
	_gameInput.hunger_stat_bar.value = min_ham
	_gameInput.thirst_stat_bar.max_value = max_agua
	_gameInput.thirst_stat_bar.value = min_agua

func _on_bank_gold_updated(gold: int) -> void:
	_gameInput.SetBankGold(gold)

func _on_attributes_received(attributes: Array) -> void:
	_gameInput.update_stats_attributes(attributes)

func _on_skills_received(skills: Array) -> void:
	_gameInput._show_skills_window(skills)
	_gameInput.update_stats_skills(skills)

func _on_fame_received(fame: Dictionary) -> void:
	_gameInput.update_stats_fame(fame)

func _on_mini_stats_received(data: Dictionary) -> void:
	_gameInput.update_stats_ministats(data)

#endregion

#region Protocol Signal Handlers - Console/Commerce

func _on_console_message(message: String, font_data: FontData) -> void:
	_gameInput.ShowConsoleMessage(message, font_data)

func _on_damage_created(x: int, y: int, damage: int, damage_type: int) -> void:
	if _gameWorld:
		_gameWorld.AddDamageText(x, y, damage, damage_type)

func _on_show_message_box(message: String) -> void:
	Utils.ShowAlertDialog("Server", message, get_parent())

func _on_commerce_init() -> void:
	_gameInput.OpenMerchant()

func _on_commerce_end() -> void:
	_gameInput.CloseMerchant()

func _on_bank_init(gold: int) -> void:
	_gameInput.OpenBank()
	_gameInput.SetBankGold(gold)

func _on_bank_end() -> void:
	_gameInput.CloseBank()

func _on_stop_working() -> void:
	_gameInput.ShowConsoleMessage("¡Has terminado de trabajar!", \
		GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])

func _on_pong_received(ping_ms: int) -> void:
	var ping_color: Color
	if ping_ms < 20:
		ping_color = Color.GREEN
	elif ping_ms < 90:
		ping_color = Color.YELLOW
	else:
		ping_color = Color.RED
	_gameInput.ShowConsoleMessage("Ping: %d ms" % ping_ms, FontData.new(ping_color))

#endregion

#region Protocol Signal Handlers - Guilds

func _on_show_guild_align() -> void:
	var alignment_window_scene = preload("res://ui/hub/guild_alignment_window.tscn")
	var alignment_window = alignment_window_scene.instantiate()
	get_parent().add_child(alignment_window)
	alignment_window.popup_centered()

func _on_show_guild_fundation_form() -> void:
	if _gameInput and _gameInput.has_method("show_guild_foundation_window"):
		_gameInput.show_guild_foundation_window()

func _on_guild_list(guilds: Array) -> void:
	_gameInput.show_guild_list(guilds)

func _on_guild_member_info(names: Array, members: Array) -> void:
	_gameInput.show_guild_member_info(names, members)

func _on_guild_leader_info(names: Array, members: Array, news: String, requests: Array) -> void:
	_gameInput.update_guild_leader_data(names, members, news, requests)

func _on_guild_details(data: Dictionary) -> void:
	_gameInput.show_guild_details(data)

func _on_guild_news(news: String, enemies: Array, allies: Array) -> void:
	_gameInput.show_guild_news(news, enemies, allies)

func _on_offer_details(details: String) -> void:
	_gameInput.show_offer_details(details)

func _on_alliance_proposals(guilds: Array) -> void:
	_gameInput.show_alliance_proposals(guilds)

func _on_peace_proposals(guilds: Array) -> void:
	_gameInput.show_peace_proposals(guilds)

func _on_trainer_creature_list(creatures: Array) -> void:
	_gameInput.show_spawn_list(creatures)

#endregion

#region Protocol Signal Handlers - Multi-Message

func _on_multi_message(index: int, arg1: int, arg2: int, arg3: int, string_arg1: String) -> void:
	match index:
		Enums.Messages.SafeModeOn:
			_gameInput.ShowConsoleMessage(">>SEGURO ACTIVADO<<", FontData.new(Color.GREEN, true))
		Enums.Messages.SafeModeOff:
			_gameInput.ShowConsoleMessage(">>SEGURO DESACTIVADO<<", FontData.new(Color.RED, true))
		Enums.Messages.ResuscitationSafeOn:
			_gameInput.ShowConsoleMessage("SEGURO DE RESURRECCION ACTIVADO", FontData.new(Color.GREEN, true))
		Enums.Messages.ResuscitationSafeOff:
			_gameInput.ShowConsoleMessage("SEGURO DE RESURRECCION DESACTIVADO", FontData.new(Color.RED, true))
		Enums.Messages.NPCSwing:
			_gameInput.ShowConsoleMessage("¡¡¡La criatura falló el golpe!!!", FontData.new(Color.RED, true))
		Enums.Messages.NPCKillUser:
			_gameInput.ShowConsoleMessage("¡¡¡La criatura te ha matado!!!", FontData.new(Color.RED, true))
		Enums.Messages.BlockedWithShieldUser:
			_gameInput.ShowConsoleMessage("¡¡¡Has rechazado el ataque con el escudo!!!", FontData.new(Color.RED, true))
		Enums.Messages.BlockedWithShieldOther:
			_gameInput.ShowConsoleMessage("¡¡¡El usuario rechazó el ataque con su escudo!!!", FontData.new(Color.RED, true))
		Enums.Messages.UserSwing:
			_gameInput.ShowConsoleMessage("¡¡¡Has fallado el golpe!!!", FontData.new(Color.RED, true))
		Enums.Messages.NobilityLost:
			_gameInput.ShowConsoleMessage("¡Has perdido nobleza y ganado criminalidad!", FontData.new(Color.RED))
		Enums.Messages.CantUseWhileMeditating:
			_gameInput.ShowConsoleMessage("¡Estás meditando! Debes dejar de meditar para usar objetos.", FontData.new(Color.RED))
		Enums.Messages.NPCHitUser:
			var body_part_msg = Consts.MessageNPCHitUser.get(arg1, "")
			if body_part_msg:
				_gameInput.ShowConsoleMessage(body_part_msg.format([arg2]), FontData.new(Color.RED, true))
		Enums.Messages.UserHitNPC:
			_gameInput.ShowConsoleMessage("¡¡Le has pegado a la criatura por %d!!" % arg1, FontData.new(Color.RED, true))
		Enums.Messages.UserAttackedSwing:
			var char_name = _gameWorld.GetCharacter(arg1).GetCharacterName() if _gameWorld.GetCharacter(arg1) else "?"
			_gameInput.ShowConsoleMessage("¡¡%s te atacó y falló!!" % char_name, FontData.new(Color.RED, true))
		Enums.Messages.UserHittedByUser:
			var char_name = _gameWorld.GetCharacter(arg1).GetCharacterName() if _gameWorld.GetCharacter(arg1) else "?"
			_gameInput.ShowConsoleMessage(Consts.MessageUserHittedByUser[arg2].format([char_name, arg3]), FontData.new(Color.RED))
		Enums.Messages.UserHittedUser:
			var char_name = _gameWorld.GetCharacter(arg1).GetCharacterName() if _gameWorld.GetCharacter(arg1) else "?"
			_gameInput.ShowConsoleMessage(Consts.MessageUserHittedUser[arg2].format([char_name, arg3]), FontData.new(Color.RED))
		Enums.Messages.HaveKilledUser:
			var char_name = _gameWorld.GetCharacter(arg1).GetCharacterName() if _gameWorld.GetCharacter(arg1) else "?"
			_gameInput.ShowConsoleMessage("Has matado a %s!" % char_name, FontData.new(Color.RED, true))
			_gameInput.ShowConsoleMessage("Has ganado %d puntos de experiencia." % arg2, FontData.new(Color.RED, true))
		Enums.Messages.UserKill:
			var char_name = _gameWorld.GetCharacter(arg1).GetCharacterName() if _gameWorld.GetCharacter(arg1) else "?"
			_gameInput.ShowConsoleMessage("%s te ha matado!" % char_name, FontData.new(Color.RED, true))
		Enums.Messages.GoHome:
			var message = ""
			if arg2 >= 60:
				if arg2 % 60 == 0:
					message = "%d minutos." % (arg2 / 60.0)
				else:
					message = "%d minutos y %d segundos." % [int(arg2 / 60.0), int(arg2) % 60]
			else:
				message = "%d segundos." % arg2
			_gameInput.ShowConsoleMessage("Te encuentras a %d mapas de la %s, este viaje durará %s" % [arg1, string_arg1, message], FontData.new(Color.RED, true))
		Enums.Messages.FinishHome:
			_gameInput.ShowConsoleMessage("Has llegado a tu hogar. El viaje ha finalizado.", FontData.new(Color.WHITE))
		Enums.Messages.CancelGoHome:
			_gameInput.ShowConsoleMessage("Tu viaje ha sido cancelado.", FontData.new(Color.RED))

func _on_work_request_target(skill_id: int) -> void:
	_gameInput.ShowConsoleMessage(Consts.MessageWorkRequestTarget[skill_id], FontData.new(Color.from_rgba8(100, 100, 120)))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Global.useCustomCursor and _crosshair_cursor:
		if _scaled_crosshair_cursor == null:
			_scaled_crosshair_cursor = _scale_cursor(_crosshair_cursor, 0.1)
		var cursor_to_use = _scaled_crosshair_cursor if _scaled_crosshair_cursor else _crosshair_cursor
		var image_size = cursor_to_use.get_size()
		var hotspot = Vector2(image_size.x / 2, image_size.y / 2)
		Input.set_custom_mouse_cursor(cursor_to_use, Input.CURSOR_ARROW, hotspot)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)

#endregion

#region Utility Functions

func _FlushData() -> void:
	if not GameProtocol.IsEmpty():
		ClientInterface.Send(GameProtocol.Flush())

func _OnPingTimerTimeout() -> void:
	if _gameContext.pingTime != 0:
		return
	GameProtocol.WritePing()
	_FlushData()
	_gameContext.pingTime = Time.get_ticks_msec()

#endregion
