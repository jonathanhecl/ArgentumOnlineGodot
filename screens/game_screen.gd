extends Node
class_name GameScreen

# Cursor personalizado para selección de objetivo
var _crosshair_cursor: Texture2D = null
var _scaled_crosshair_cursor = null
@export var _gameInput:HubController
@export var _gameWorld:GameWorld
@export var _camera:Camera2D

var _input:Dictionary[String, int] = {
	"ui_left" = Enums.Heading.West,
	"ui_right" = Enums.Heading.East,
	"ui_up" = Enums.Heading.North,
	"ui_down" = Enums.Heading.South,
}

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

func _exit_tree() -> void:
	# Limpiar referencias globales
	ProtocolHandler.game_world = null
	ProtocolHandler.hub_controller = null
	
	# Desconectar señales al salir para evitar llamadas a nodos destruidos
	if ClientInterface.disconnected.is_connected(_OnDisconnected):
		ClientInterface.disconnected.disconnect(_OnDisconnected)
	
	_disconnect_protocol_signals()

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
	
	_gameInput.minimap.update_player_position(character.gridPosition.x, character.gridPosition.y)
	 
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
	
	# Commerce signals
	ProtocolHandler.commerce_init.connect(_on_commerce_init)
	ProtocolHandler.commerce_end.connect(_on_commerce_end)
	ProtocolHandler.bank_init.connect(_on_bank_init)
	ProtocolHandler.bank_end.connect(_on_bank_end)
	ProtocolHandler.bank_gold_updated.connect(_on_bank_gold_updated)
	
	# Status toggles
	ProtocolHandler.stop_working.connect(_on_stop_working)
	ProtocolHandler.pong_received.connect(_on_pong_received)
	
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
		"character_change_nick", "user_char_index_received", "set_invisible", "fx_created",
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
		"work_request_target"
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

func _on_character_removed(char_index: int) -> void:
	_gameWorld.DeleteCharacter(char_index)

func _on_character_moved(char_index: int, x: int, y: int) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character == null:
		return
	var addX = x - character.gridPosition.x
	var addY = y - character.gridPosition.y
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
	character.renderer.heading = data.heading

func _on_character_change_nick(char_index: int, char_name: String) -> void:
	var character = _gameWorld.GetCharacter(char_index)
	if character:
		character.SetCharacterName(char_name)

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
	_gameWorld.SwitchMap(map_id)
	_gameInput.minimap.load_thumbnail(map_id)

func _on_pos_updated(x: int, y: int) -> void:
	var character = _gameWorld.GetCharacter(_mainCharacterInstanceId)
	if character:
		character.StopMoving()
		character.gridPosition = Vector2i(x, y)
		character.position = Vector2((x - 1) * 32, (y - 1) * 32) + Vector2(16, 32)
		_gameInput.minimap.update_player_position(x, y)

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
		Enums.Messages.BlockedWithShieldother:
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
		Enums.Messages.Home:
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
		Enums.Messages.CancelHome:
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
