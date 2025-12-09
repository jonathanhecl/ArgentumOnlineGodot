extends Node
## Manejador global de protocolo del servidor.
## Procesa TODOS los paquetes en un solo lugar.
## Las clases de comandos (ShowGuildAlign, Atributes, etc.) son globales via class_name.

#region Señales - Eventos de Login/Cuenta
signal error_msg_received(message: String)
signal account_logged(account_name: String, account_hash: String, characters: Array)
signal show_message_box(message: String)
signal logged_in()
#endregion

#region Señales - Eventos de Juego
signal character_created(data: CharacterCreate)
signal character_removed(char_index: int)
signal character_moved(char_index: int, x: int, y: int)
signal character_changed(data: CharacterChange)
signal character_change_nick(char_index: int, name: String)
signal user_char_index_received(char_index: int)

signal map_changed(map_id: int, version: int)
signal area_changed()
signal pos_updated(x: int, y: int)
signal force_char_move(heading: int)

signal object_created(grh_id: int, x: int, y: int)
signal object_deleted(x: int, y: int)
signal block_position_changed(x: int, y: int, blocked: bool)

signal inventory_slot_changed(slot: int, item_stack: ItemStack)
signal spell_slot_changed(slot: int, name: String)
signal bank_slot_changed(slot: int, item_stack: ItemStack)
signal npc_inventory_slot_changed(slot: int, item_stack: ItemStack)

signal stats_updated(data: UpdateUserStats)
signal hp_updated(hp: int)
signal mana_updated(mana: int)
signal stamina_updated(sta: int)
signal gold_updated(gold: int)
signal exp_updated(exp: int)
signal level_up(skill_points: int)
signal strength_updated(value: int)
signal dexterity_updated(value: int)
signal strength_dexterity_updated(strength: int, dexterity: int)
signal hunger_thirst_updated(min_ham: int, max_ham: int, min_agua: int, max_agua: int)
signal bank_gold_updated(gold: int)
signal attributes_received(attributes: Array)
signal skills_received(skills: Array)
signal fame_received(fame: Dictionary)
signal mini_stats_received(data: Dictionary)

signal console_message(message: String, font_data: FontData)
signal chat_over_head(char_index: int, message: String, color: Color)
signal remove_char_dialog(char_index: int)
signal remove_all_dialogs()

signal fx_created(char_index: int, fx: int, loops: int)
signal set_invisible(char_index: int, invisible: bool)
signal update_tag_and_status(char_index: int, tag: String, nick_color: int)

signal play_midi(midi_id: int, loops: int)
signal play_wave(wave_id: int, x: int, y: int)
signal rain_toggle()
signal send_night(time: int)

signal commerce_init()
signal commerce_end()
signal user_commerce_init(trader_name: String)
signal user_commerce_end()
signal user_offer_confirm()
signal cancel_offer_item(slot: int)
signal commerce_chat(message: String, color: Color)

signal bank_init(gold: int)
signal bank_end()

signal blind_toggle(is_blind: bool)
signal dumb_toggle(is_dumb: bool)
signal paralize_toggle()
signal rest_toggle()
signal meditate_toggle()
signal navigate_toggle()
signal pause_toggle()
signal stop_working()
signal safe_mode_changed(enabled: bool)
signal resuscitation_safe_changed(enabled: bool)
signal work_request_target(skill_id: int)

signal blacksmith_weapons_received(items: Array)
signal blacksmith_armors_received(items: Array)

signal guild_list_received(guilds: Array)
signal guild_member_info_received(names: Array, members: Array)
signal guild_leader_info_received(names: Array, members: Array, news: String, requests: Array)
signal guild_details_received(data: Dictionary)
signal guild_news_received(news: String, enemies: Array, allies: Array)
signal guild_chat_received(message: String)
signal offer_details_received(details: String)
signal alliance_proposals_received(guilds: Array)
signal peace_proposals_received(guilds: Array)
signal show_guild_align()
signal show_guild_fundation_form()

signal trainer_creature_list_received(creatures: Array)

signal pong_received(ping_ms: int)

signal multi_message_received(index: int, arg1: int, arg2: int, arg3: int, string_arg1: String)
#endregion

# Buffer de mensajes pendientes
var _pending_messages: Array[PackedByteArray] = []

# Estado del juego global
var game_context: GameContext = GameContext.new()
var main_character_id: int = -1

# Referencia al GameWorld (se setea desde game_screen)
var game_world: GameWorld = null

# Referencia al HubController (se setea desde game_screen)
var hub_controller: HubController = null

func _ready() -> void:
	ClientInterface.dataReceived.connect(_on_data_received)

func _on_data_received(data: PackedByteArray) -> void:
	_pending_messages.push_back(data)

func _process(_delta: float) -> void:
	_process_pending_messages()

func _process_pending_messages() -> void:
	while not _pending_messages.is_empty():
		var data = _pending_messages.pop_front()
		_handle_incoming_data(data)

func _handle_incoming_data(data: PackedByteArray) -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = data
	
	while stream.get_position() < stream.get_size():
		_handle_one_packet(stream)

func _handle_one_packet(stream: StreamPeerBuffer) -> void:
	var packet_id = stream.get_u8()
	var packet_name = ""
	
	if packet_id < Enums.ServerPacketID.keys().size():
		packet_name = Enums.ServerPacketID.keys()[packet_id]
	else:
		print("[ProtocolHandler] Paquete desconocido ID: ", packet_id)
		return
	
	match packet_id:
		# ==================== LOGIN/ACCOUNT PACKETS ====================
		Enums.ServerPacketID.ErrorMsg:
			var msg = ErrorMsg.new(stream)
			error_msg_received.emit(msg.message)
		
		Enums.ServerPacketID.AccountLogged:
			_handle_account_logged(stream)
		
		Enums.ServerPacketID.ShowMessageBox:
			var msg = ShowMessageBox.new(stream)
			show_message_box.emit(msg.message)
		
		Enums.ServerPacketID.Logged:
			var _p = Logged.new(stream)
			logged_in.emit()
		
		# ==================== CHARACTER PACKETS ====================
		Enums.ServerPacketID.CharacterCreate:
			var p = CharacterCreate.new(stream)
			_process_character_privileges(p)
			character_created.emit(p)
		
		Enums.ServerPacketID.CharacterRemove:
			var p = CharacterRemove.new(stream)
			character_removed.emit(p.charIndex)
		
		Enums.ServerPacketID.CharacterMove:
			var p = CharacterMove.new(stream)
			character_moved.emit(p.charIndex, p.x, p.y)
		
		Enums.ServerPacketID.CharacterChange:
			var p = CharacterChange.new(stream)
			character_changed.emit(p)
		
		Enums.ServerPacketID.CharacterChangeNick:
			var p = CharacterChangeNick.new(stream)
			character_change_nick.emit(p.char_index, p.char_name)
		
		Enums.ServerPacketID.UserCharIndexInServer:
			var p = UserCharIndexInServer.new(stream)
			main_character_id = p.charIndex
			user_char_index_received.emit(p.charIndex)
		
		Enums.ServerPacketID.UserIndexInServer:
			UserIndexInServer.new(stream) # Solo consume el paquete
		
		Enums.ServerPacketID.SetInvisible:
			var p = SetInvisible.new(stream)
			set_invisible.emit(p.charIndex, p.invisible)
		
		Enums.ServerPacketID.CreateFX:
			var p = CreateFx.new(stream)
			fx_created.emit(p.charIndex, p.fx, p.fxLoops)
		
		Enums.ServerPacketID.UpdateTagAndStatus:
			var p = UpdateTagAndStatus.new(stream)
			update_tag_and_status.emit(p.charIndex, p.userTag, p.nickColor)
		
		Enums.ServerPacketID.ChatOverHead:
			var p = ChatOverHead.new(stream)
			chat_over_head.emit(p.charIndex, p.chat, p.color)
		
		Enums.ServerPacketID.RemoveCharDialog:
			var p = RemoveCharDialog.new(stream)
			remove_char_dialog.emit(p.charIndex)
		
		Enums.ServerPacketID.RemoveDialogs:
			remove_all_dialogs.emit()
		
		# ==================== MAP/POSITION PACKETS ====================
		Enums.ServerPacketID.ChangeMap:
			var p = ChangeMap.new(stream)
			game_context.player_map = p.mapId
			map_changed.emit(p.mapId, p.version)
		
		Enums.ServerPacketID.AreaChanged:
			var _p = AreaChanged.new(stream)
			area_changed.emit()
		
		Enums.ServerPacketID.PosUpdate:
			var p = PosUpdate.new(stream)
			pos_updated.emit(p.x, p.y)
		
		Enums.ServerPacketID.ForceCharMove:
			var p = ForceCharMove.new(stream)
			force_char_move.emit(p.heading)
		
		Enums.ServerPacketID.ObjectCreate:
			var p = ObjectCreate.new(stream)
			object_created.emit(p.grhId, p.x, p.y)
		
		Enums.ServerPacketID.ObjectDelete:
			var p = ObjectDelete.new(stream)
			object_deleted.emit(p.x, p.y)
		
		Enums.ServerPacketID.BlockPosition:
			var p = BlockPosition.new(stream)
			block_position_changed.emit(p.x, p.y, p.blocked)
		
		# ==================== INVENTORY/ITEMS PACKETS ====================
		Enums.ServerPacketID.ChangeInventorySlot:
			var p = ChangeInventorySlot.new(stream)
			var item_stack = _create_item_stack(p)
			game_context.playerInventory.SetSlot(p.slot - 1, item_stack)
			inventory_slot_changed.emit(p.slot - 1, item_stack)
		
		Enums.ServerPacketID.ChangeSpellSlot:
			var p = ChangeSpellSlot.new(stream)
			spell_slot_changed.emit(p.slot - 1, p.name)
		
		Enums.ServerPacketID.ChangeBankSlot:
			var p = ChangeBankSlot.new(stream)
			var item_stack = _create_bank_item_stack(p)
			game_context.bankInventory.SetSlot(p.slot - 1, item_stack)
			bank_slot_changed.emit(p.slot - 1, item_stack)
		
		Enums.ServerPacketID.ChangeNPCInventorySlot:
			var p = ChangeNPCInventorySlot.new(stream)
			var item_stack = _create_npc_item_stack(p)
			game_context.merchantInventory.SetSlot(p.slot - 1, item_stack)
			npc_inventory_slot_changed.emit(p.slot - 1, item_stack)
		
		# ==================== STATS PACKETS ====================
		Enums.ServerPacketID.UpdateUserStats:
			var p = UpdateUserStats.new(stream)
			_update_game_context_stats(p)
			stats_updated.emit(p)
		
		Enums.ServerPacketID.UpdateHP:
			var p = UpdateHP.new(stream)
			game_context.player_stats.hp = p.hp
			hp_updated.emit(p.hp)
		
		Enums.ServerPacketID.UpdateMana:
			var p = UpdateMana.new(stream)
			game_context.player_stats.mana = p.min_mana
			mana_updated.emit(p.min_mana)
		
		Enums.ServerPacketID.UpdateSta:
			var p = UpdateSta.new(stream)
			game_context.player_stats.sta = p.stamina
			stamina_updated.emit(p.stamina)
		
		Enums.ServerPacketID.UpdateGold:
			var p = UpdateGold.new(stream)
			game_context.player_gold = p.gold
			gold_updated.emit(p.gold)
		
		Enums.ServerPacketID.UpdateExp:
			var p = UpdateExp.new(stream)
			game_context.player_experience = p.experience
			exp_updated.emit(p.experience)
		
		Enums.ServerPacketID.LevelUp:
			var p = LevelUp.new(stream)
			level_up.emit(p.skillPoints)
		
		Enums.ServerPacketID.UpdateStrenght:
			var p = UpdateStrenght.new(stream)
			strength_updated.emit(p.strenght)
		
		Enums.ServerPacketID.UpdateDexterity:
			var p = UpdateDexterity.new(stream)
			dexterity_updated.emit(p.dexterity)
		
		Enums.ServerPacketID.UpdateStrenghtAndDexterity:
			var p = UpdateStrengthAndDexterity.new(stream)
			strength_dexterity_updated.emit(p.strength, p.dexterity)
		
		Enums.ServerPacketID.UpdateHungerAndThirst:
			var p = UpdateHungerAndThirst.new(stream)
			hunger_thirst_updated.emit(p.minHam, p.maxHam, p.minAgua, p.maxAgua)
		
		Enums.ServerPacketID.UpdateBankGold:
			var p = UpdateBankGold.new(stream)
			bank_gold_updated.emit(p.gold)
		
		Enums.ServerPacketID.Atributes:
			var p = Atributes.new(stream)
			attributes_received.emit(p.attributes)
		
		Enums.ServerPacketID.SendSkills:
			var p = SendSkills.new(stream)
			skills_received.emit(p.skills)
		
		Enums.ServerPacketID.Fame:
			var p = Fame.new(stream)
			var fame = {
				"AsesinoRep": p.AsesinoRep,
				"BandidoRep": p.BandidoRep,
				"BurguesRep": p.BurguesRep,
				"LadronesRep": p.LadronesRep,
				"NobleRep": p.NobleRep,
				"PlebeRep": p.PlebeRep,
				"Promedio": p.Promedio,
			}
			fame_received.emit(fame)
		
		Enums.ServerPacketID.MiniStats:
			var p = MiniStats.new(stream)
			var data = {
				"CiudadanosMatados": p.CiudadanosMatados,
				"CriminalesMatados": p.CriminalesMatados,
				"UsuariosMatados": p.UsuariosMatados,
				"NpcsMatados": p.NpcsMatados,
				"Clase": p.Clase,
				"PenaCarcel": p.PenaCarcel,
			}
			mini_stats_received.emit(data)
		
		# ==================== CONSOLE/CHAT PACKETS ====================
		Enums.ServerPacketID.ConsoleMsg:
			var p = ConsoleMessage.new(stream)
			console_message.emit(p.message, GameAssets.FontDataList[p.fontIndex])
		
		Enums.ServerPacketID.GuildChat:
			var p = GuildChat.new(stream)
			guild_chat_received.emit(p.chat)
		
		# ==================== AUDIO PACKETS ====================
		Enums.ServerPacketID.PlayMIDI:
			var p = PlayMidi.new(stream)
			play_midi.emit(p.midiId, p.loops)
		
		Enums.ServerPacketID.PlayWave:
			var p = PlayWave.new(stream)
			AudioManager.PlayAudio(p.wave, true)
			play_wave.emit(p.wave, p.x, p.y)
		
		Enums.ServerPacketID.RainToggle:
			rain_toggle.emit()
		
		Enums.ServerPacketID.SendNight:
			var p = SendNight.new(stream)
			send_night.emit(p.time)
		
		# ==================== COMMERCE PACKETS ====================
		Enums.ServerPacketID.CommerceInit:
			commerce_init.emit()
		
		Enums.ServerPacketID.CommerceEnd:
			game_context.trading = false
			commerce_end.emit()
		
		Enums.ServerPacketID.UserCommerceInit:
			var p = UserCommerceInit.new(stream)
			user_commerce_init.emit(p.userName)
		
		Enums.ServerPacketID.UserCommerceEnd:
			game_context.trading = false
			user_commerce_end.emit()
		
		Enums.ServerPacketID.UserOfferConfirm:
			user_offer_confirm.emit()
		
		Enums.ServerPacketID.CancelOfferItem:
			var p = CancelOfferItem.new(stream)
			cancel_offer_item.emit(p.slot)
		
		Enums.ServerPacketID.CommerceChat:
			var p = CommerceChat.new(stream)
			commerce_chat.emit(p.message, p.font_index)
		
		# ==================== BANK PACKETS ====================
		Enums.ServerPacketID.BankInit:
			var p = BankInit.new(stream)
			bank_init.emit(p.gold)
		
		Enums.ServerPacketID.BankEnd:
			bank_end.emit()
		
		# ==================== STATUS TOGGLE PACKETS ====================
		Enums.ServerPacketID.Blind:
			game_context.userCiego = true
			blind_toggle.emit(true)
		
		Enums.ServerPacketID.BlindNoMore:
			game_context.userCiego = false
			blind_toggle.emit(false)
		
		Enums.ServerPacketID.Dumb:
			game_context.userEstupido = true
			dumb_toggle.emit(true)
		
		Enums.ServerPacketID.DumbNoMore:
			game_context.userEstupido = false
			dumb_toggle.emit(false)
		
		Enums.ServerPacketID.ParalizeOK:
			game_context.userParalizado = not game_context.userParalizado
			paralize_toggle.emit()
		
		Enums.ServerPacketID.RestOK:
			game_context.userDescansar = not game_context.userDescansar
			rest_toggle.emit()
		
		Enums.ServerPacketID.MeditateToggle:
			game_context.userMeditar = not game_context.userMeditar
			meditate_toggle.emit()
		
		Enums.ServerPacketID.NavigateToggle:
			game_context.userNavegando = not game_context.userNavegando
			navigate_toggle.emit()
		
		Enums.ServerPacketID.PauseToggle:
			game_context.pause = not game_context.pause
			pause_toggle.emit()
		
		Enums.ServerPacketID.StopWorking:
			stop_working.emit()
		
		# ==================== CRAFTING PACKETS ====================
		Enums.ServerPacketID.BlacksmithWeapons:
			var p = BlacksmithWeapons.new(stream)
			blacksmith_weapons_received.emit(p.items)
		
		Enums.ServerPacketID.BlacksmithArmors:
			var p = BlacksmithArmors.new(stream)
			blacksmith_armors_received.emit(p.items)
		
		# ==================== GUILD PACKETS ====================
		Enums.ServerPacketID.ShowGuildAlign:
			var _p = ShowGuildAlign.from_buffer(stream, null)
			show_guild_align.emit()
		
		Enums.ServerPacketID.ShowGuildFundationForm:
			var _p = ShowGuildFundationForm.from_buffer(stream, null)
			show_guild_fundation_form.emit()
		
		Enums.ServerPacketID.GuildList:
			var p = GuildList.new(stream)
			guild_list_received.emit(p.guilds)
		
		Enums.ServerPacketID.GuildMemberInfo:
			var p = GuildMemberInfo.new(stream)
			guild_member_info_received.emit(p.guild_names, p.guild_members)
		
		Enums.ServerPacketID.GuildLeaderInfo:
			var p = GuildLeaderInfo.new(stream)
			guild_leader_info_received.emit(p.guild_names, p.guild_members, p.guild_news, p.guild_requests)
		
		Enums.ServerPacketID.GuildDetails:
			var p = GuildDetails.new(stream)
			var data = {
				"name": p.guild_name,
				"founder": p.founder,
				"creation_date": p.creation_date,
				"leader": p.leader,
				"website": p.website,
				"members_count": p.members_count,
				"elections_open": p.elections_open,
				"alignment": p.alignment,
				"enemies_count": p.enemies_count,
				"allies_count": p.allies_count,
				"anti_faction": p.anti_faction,
				"codex": p.codex,
				"description": p.description,
				"is_leader": p.is_leader
			}
			guild_details_received.emit(data)
		
		Enums.ServerPacketID.GuildNews:
			var p = GuildNews.new(stream)
			guild_news_received.emit(p.news, p.enemy_guilds, p.allied_guilds)
		
		Enums.ServerPacketID.OfferDetails:
			var p = OfferDetails.new(stream)
			offer_details_received.emit(p.details)
		
		Enums.ServerPacketID.AlianceProposalsList:
			var p = AllianceProposalsList.new(stream)
			alliance_proposals_received.emit(p.guilds)
		
		Enums.ServerPacketID.PeaceProposalsList:
			var p = PeaceProposalsList.new(stream)
			peace_proposals_received.emit(p.guilds)
		
		# ==================== TRAINER PACKETS ====================
		Enums.ServerPacketID.TrainerCreatureList:
			var p = TrainerCreatureList.new(stream)
			trainer_creature_list_received.emit(p.creatures)
		
		# ==================== MISC PACKETS ====================
		Enums.ServerPacketID.Pong:
			var ping_ms = Time.get_ticks_msec() - game_context.pingTime
			game_context.pingTime = 0
			pong_received.emit(ping_ms)
		
		Enums.ServerPacketID.MultiMessage:
			var p = MultiMessage.new(stream)
			_handle_multi_message(p)
		
		_:
			print("[ProtocolHandler] Paquete no manejado: ", packet_name, " (ID: ", packet_id, ")")

#region Helper Methods

func _handle_account_logged(stream: StreamPeerBuffer) -> void:
	var account_name = Utils.GetUnicodeString(stream)
	var account_hash = Utils.GetUnicodeString(stream)
	var num_characters = stream.get_u8()
	
	var characters: Array[Dictionary] = []
	for i in range(num_characters):
		var char_data = {
			"name": Utils.GetUnicodeString(stream),
			"body": stream.get_16(),
			"head": stream.get_16(),
			"weapon": stream.get_16(),
			"shield": stream.get_16(),
			"helmet": stream.get_16(),
			"class": stream.get_u8(),
			"race": stream.get_u8(),
			"map": stream.get_16(),
			"level": stream.get_u8(),
			"gold": stream.get_32(),
			"criminal": stream.get_u8() != 0,
			"dead": stream.get_u8() != 0,
			"gm": stream.get_u8() != 0
		}
		characters.append(char_data)
	
	# Guardar en Global
	Global.account_name = account_name
	Global.account_hash = account_hash
	Global.account_characters = characters
	
	account_logged.emit(account_name, account_hash, characters)

func _process_character_privileges(p: CharacterCreate) -> void:
	var privileges = p.privileges
	if privileges != 0:
		if (privileges & Enums.PlayerType.ChaosCouncil) != 0 and (privileges & Enums.PlayerType.User) == 0:
			privileges = privileges ^ Enums.PlayerType.ChaosCouncil
		
		if (privileges & Enums.PlayerType.RoyalCouncil) != 0 and (privileges & Enums.PlayerType.User) == 0:
			privileges = privileges ^ Enums.PlayerType.RoyalCouncil
		
		if (privileges & Enums.PlayerType.RoleMaster) != 0:
			privileges = Enums.PlayerType.RoleMaster
		
		privileges = int(log(privileges) / log(2))
	
	p.privileges = privileges

func _create_item_stack(p: ChangeInventorySlot) -> ItemStack:
	var item = Item.new()
	item.index = p.index
	item.name = p.name
	item.type = p.type
	item.maxHit = p.maxHit
	item.minHit = p.minHit
	item.maxDef = p.maxDef
	item.minDef = p.minDef
	item.salePrice = p.salePrice
	
	if p.grhId > 0:
		item.icon = GameAssets.GetTexture(GameAssets.GrhDataList[p.grhId].fileId)
	
	return ItemStack.new(p.amount, p.equipped, item)

func _create_bank_item_stack(p: ChangeBankSlot) -> ItemStack:
	var item = Item.new()
	item.index = p.index
	item.name = p.name
	item.type = p.type
	item.maxHit = p.maxHit
	item.minHit = p.minHit
	item.maxDef = p.maxDef
	item.minDef = p.minDef
	item.salePrice = p.salePrice
	
	if p.grhId > 0:
		item.icon = GameAssets.GetTexture(GameAssets.GrhDataList[p.grhId].fileId)
	
	return ItemStack.new(p.amount, false, item)

func _create_npc_item_stack(p: ChangeNPCInventorySlot) -> ItemStack:
	var item = Item.new()
	item.index = p.index
	item.name = p.name
	item.type = p.type
	item.maxHit = p.maxHit
	item.minHit = p.minHit
	item.maxDef = p.maxDef
	item.minDef = p.minDef
	item.salePrice = p.salePrice
	
	if p.grhId > 0:
		item.icon = GameAssets.GetTexture(GameAssets.GrhDataList[p.grhId].fileId)
	
	return ItemStack.new(p.amount, false, item)

func _update_game_context_stats(p: UpdateUserStats) -> void:
	game_context.player_level = p.elv
	game_context.player_gold = p.gold
	game_context.player_experience = p.experience
	game_context.player_experience_to_next_level = p.elu
	game_context.player_stats.max_hp = p.maxHp
	game_context.player_stats.hp = p.minHp
	game_context.player_stats.max_mana = p.maxMana
	game_context.player_stats.mana = p.minMana
	game_context.player_stats.max_sta = p.maxSta
	game_context.player_stats.sta = p.minSta

func _handle_multi_message(p: MultiMessage) -> void:
	# Emitir señal genérica para que las pantallas manejen los mensajes específicos
	multi_message_received.emit(p.index, p.arg1, p.arg2, p.arg3, p.string_arg1)
	
	# Manejar mensajes que afectan el estado del juego
	match p.index:
		Enums.Messages.SafeModeOn:
			safe_mode_changed.emit(true)
		Enums.Messages.SafeModeOff:
			safe_mode_changed.emit(false)
		Enums.Messages.ResuscitationSafeOn:
			resuscitation_safe_changed.emit(true)
		Enums.Messages.ResuscitationSafeOff:
			resuscitation_safe_changed.emit(false)
		Enums.Messages.WorkRequestTarget:
			game_context.usingSkill = p.arg1
			work_request_target.emit(p.arg1)
		Enums.Messages.Home:
			game_context.traveling = true
		Enums.Messages.FinishHome, Enums.Messages.CancelHome:
			game_context.traveling = false

#endregion
