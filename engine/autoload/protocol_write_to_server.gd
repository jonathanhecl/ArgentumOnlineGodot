extends Node

static var _writer:StreamPeerBuffer = StreamPeerBuffer.new()

# Función para registrar comandos salientes al servidor
static func _log_outgoing_packet(packet_name: String, params: String = "") -> void:
	if Global.log_outgoing_packets:
		var log_message = "[OUTGOING] " + packet_name
		if params != "":
			log_message += " | " + params
		print(log_message)

static func Flush() -> PackedByteArray:
	var data = _writer.data_array
	print("[DEBUG] Flush() - Enviando ", data.size(), " bytes: ", data)
	_writer.clear() 
	return data
	
static func IsEmpty() -> bool:
	return _writer.get_size() == 0

static func Clear() -> void:
	_writer.clear()

static func WriteLoginExistingCharacter(char_name: String, account_hash: String) -> void:
	_log_outgoing_packet("LoginExistingCharacter", "char_name: " + char_name)
	_writer.put_u8(Enums.ClientPacketID.ClientLoginExistingChar)
	
	# Nombre del personaje
	Utils.PutUnicodeString(_writer, char_name)
	# Hash de la cuenta
	Utils.PutUnicodeString(_writer, account_hash)
	
	# Versión del cliente
	_writer.put_u8(Consts.CLIENT_VERSION_MAJOR)
	_writer.put_u8(Consts.CLIENT_VERSION_MINOR)
	_writer.put_u8(Consts.CLIENT_VERSION_REVISION)

static func WriteLoginExistingAccount(username:String, password:String) -> void:
	_log_outgoing_packet("LoginExistingAccount", "username: " + username + ", password: " + password)
	_writer.put_u8(Enums.ClientPacketID.ClientLoginExistingAccount)
	Utils.PutUnicodeString(_writer, username)
	Utils.PutUnicodeString(_writer, password)
	# Enviar versión del cliente (Major, Minor, Revision)
	_writer.put_u8(Consts.CLIENT_VERSION_MAJOR)
	_writer.put_u8(Consts.CLIENT_VERSION_MINOR)
	_writer.put_u8(Consts.CLIENT_VERSION_REVISION)

static func WriteLoginNewAccount(username:String, password:String) -> void:
	_log_outgoing_packet("LoginNewAccount", "username: " + username + ", password: " + password)
	_writer.put_u8(Enums.ClientPacketID.ClientLoginNewAccount)
	Utils.PutUnicodeString(_writer, username)
	Utils.PutUnicodeString(_writer, password)
	# Enviar versión del cliente (Major, Minor, Revision)
	_writer.put_u8(Consts.CLIENT_VERSION_MAJOR)
	_writer.put_u8(Consts.CLIENT_VERSION_MINOR)
	_writer.put_u8(Consts.CLIENT_VERSION_REVISION)
	
static func WriteLoginNewChar(username:String, account_hash:String, job:int, race:int, gender:int, home:int, head:int) -> void:
	_log_outgoing_packet("LoginNewChar", "username: " + username + ", job: " + str(job) + ", race: " + str(race) + ", gender: " + str(gender) + ", home: " + str(home) + ", head: " + str(head))
	_writer.put_u8(Enums.ClientPacketID.ClientLoginNewChar)
	
	# Nombre del personaje
	Utils.PutUnicodeString(_writer, username)
	# Hash de la cuenta
	Utils.PutUnicodeString(_writer, account_hash)
	
	# Versión del cliente
	_writer.put_u8(Consts.CLIENT_VERSION_MAJOR)
	_writer.put_u8(Consts.CLIENT_VERSION_MINOR)
	_writer.put_u8(Consts.CLIENT_VERSION_REVISION)
	
	# Datos del personaje
	_writer.put_u8(race)
	_writer.put_u8(gender)
	_writer.put_u8(job)
	_writer.put_16(head)
	
	# Hogar (ciudad inicial)
	_writer.put_u8(home)
	
static func WriteThrowDice() -> void:
	_log_outgoing_packet("ThrowDices")
	_writer.put_u8(Enums.ClientPacketID.ClientThrowDices)
	
static func WriteWalk(heading:int) -> void:
	_log_outgoing_packet("Walk", "heading: " + str(heading))
	_writer.put_u8(Enums.ClientPacketID.ClientWalk) 
	_writer.put_u8(heading)
	
	# IMPORTANTE: Desactivar macro de hechizos cuando el jugador camina
	if SpellMacroSystem.is_spell_macro_active():
		SpellMacroSystem.auto_deactivate_if_needed()
	
static func WriteChangeHeading(heading:int) -> void:
	_log_outgoing_packet("ChangeHeading", "heading: " + str(heading))
	_writer.put_u8(Enums.ClientPacketID.ClientChangeHeading) 
	_writer.put_u8(heading) 
	
static func WriteEquipItem(slot:int) -> void:
	_log_outgoing_packet("EquipItem", "slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.ClientEquipItem) 
	_writer.put_u8(slot) 
	
static func WriteUseItem(slot:int) -> void:
	_log_outgoing_packet("UseItem", "slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.ClientUseItem) 
	_writer.put_u8(slot) 
	
static func WriteQuit() -> void:
	_log_outgoing_packet("Quit")
	_writer.put_u8(Enums.ClientPacketID.ClientQuit)
	
static func WriteSafeToggle() -> void:
	_log_outgoing_packet("SafeToggle")
	_writer.put_u8(Enums.ClientPacketID.ClientSafeToggle)
	
static func WriteResuscitationToggle() -> void:
	_log_outgoing_packet("ResuscitationSafeToggle")
	_writer.put_u8(Enums.ClientPacketID.ClientResuscitationSafeToggle)
	
static func WriteDrop(slot:int, quantity:int) -> void:
	_log_outgoing_packet("Drop", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.ClientDrop) 
	_writer.put_u8(slot) 
	_writer.put_16(quantity) 
	
static func WriteDoubleClick(x:int, y:int) -> void:
	_log_outgoing_packet("DoubleClick", "x: " + str(x) + ", y: " + str(y))
	_writer.put_u8(Enums.ClientPacketID.ClientDoubleClick) 
	_writer.put_u8(x)
	_writer.put_u8(y) 

static func WriteLeftClick(x:int, y:int) -> void:
	_log_outgoing_packet("LeftClick", "x: " + str(x) + ", y: " + str(y))
	_writer.put_u8(Enums.ClientPacketID.ClientLeftClick) 
	_writer.put_u8(x)
	_writer.put_u8(y) 
	
static func WriteWork(skill:int) -> void:
	_log_outgoing_packet("Work", "skill: " + str(skill))
	_writer.put_u8(Enums.ClientPacketID.ClientWork) 
	_writer.put_u8(skill)
	
static func WriteWorkLeftClick(x:int, y:int, skill:int) -> void:
	_log_outgoing_packet("WorkLeftClick", "x: " + str(x) + ", y: " + str(y) + ", skill: " + str(skill))
	_writer.put_u8(Enums.ClientPacketID.ClientWorkLeftClick) 
	_writer.put_u8(x)
	_writer.put_u8(y) 
	_writer.put_u8(skill) 
	
static func WriteCommerceEnd() -> void:
	_log_outgoing_packet("CommerceEnd")
	_writer.put_u8(Enums.ClientPacketID.ClientCommerceEnd) 
	
static func WriteCommerceSell(slot:int, quantity:int) -> void:
	_log_outgoing_packet("CommerceSell", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.ClientCommerceSell) 
	_writer.put_u8(slot)
	_writer.put_16(quantity) 

static func WriteCommerceBuy(slot:int, quantity:int) -> void:
	_log_outgoing_packet("CommerceBuy", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.ClientCommerceBuy) 
	_writer.put_u8(slot)
	_writer.put_16(quantity) 

static func WriteCommerceStart() -> void:
	_log_outgoing_packet("CommerceStart")
	_writer.put_u8(Enums.ClientPacketID.ClientCommerceStart)

static func WriteBankStart() -> void:
	_log_outgoing_packet("BankStart")
	_writer.put_u8(Enums.ClientPacketID.ClientBankStart)
	
static func WriteBankEnd() -> void:
	_log_outgoing_packet("BankEnd")
	_writer.put_u8(Enums.ClientPacketID.ClientBankEnd)  
	
static func WriteBankExtractItem(slot:int, quantity:int) -> void:
	_log_outgoing_packet("BankExtractItem", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.ClientBankExtractItem) 
	_writer.put_u8(slot)
	_writer.put_16(quantity) 

static func WriteBankDepositItem(slot:int, quantity:int) -> void:
	_log_outgoing_packet("BankDeposit", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.ClientBankDeposit) 
	_writer.put_u8(slot)
	_writer.put_16(quantity) 
	
static func WriteBankDepositGold(quantity:int) -> void:
	_log_outgoing_packet("BankDepositGold", "quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.ClientBankDepositGold) 
	_writer.put_32(quantity)
	
static func WriteBankExtractGold(quantity:int) -> void:
	_log_outgoing_packet("BankExtractGold", "quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.ClientBankExtractGold) 
	_writer.put_32(quantity)

static func WriteRequestAccountState() -> void:
	_log_outgoing_packet("RequestAccountState")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestAccountState)

static func WriteOnline() -> void:
	_log_outgoing_packet("Online")
	_writer.put_u8(Enums.ClientPacketID.ClientOnline)

static func WriteGamble(amount:int) -> void:
	_log_outgoing_packet("Gamble", "amount: " + str(amount))
	_writer.put_u8(Enums.ClientPacketID.ClientGamble)
	_writer.put_16(amount)

static func WriteResucitate() -> void:
	_log_outgoing_packet("Resucitate")
	_writer.put_u8(Enums.ClientPacketID.ClientResucitate)

static func WriteGuildLeave() -> void:
	_log_outgoing_packet("GuildLeave")
	_writer.put_u8(Enums.ClientPacketID.ClientGuildLeave)

static func WriteHeal() -> void:
	_log_outgoing_packet("Heal")
	_writer.put_u8(Enums.ClientPacketID.ClientHeal)

static func WriteAttack() -> void:
	_log_outgoing_packet("Attack")
	_writer.put_u8(Enums.ClientPacketID.ClientAttack)

static func WritePickup() -> void:
	_log_outgoing_packet("PickUp")
	_writer.put_u8(Enums.ClientPacketID.ClientPickUp)
	
static func WriteRequestPositionUpdate() -> void:
	_log_outgoing_packet("RequestPositionUpdate")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestPositionUpdate)

static func WriteMeditate() -> void:
	_log_outgoing_packet("Meditate")
	_writer.put_u8(Enums.ClientPacketID.ClientMeditate)
	
static func WriteInitCrafting(skill_type:int) -> void:
	_log_outgoing_packet("InitCrafting", "skill_type: " + str(skill_type))
	_writer.put_u8(Enums.ClientPacketID.ClientInitCrafting)
	_writer.put_u8(skill_type)

## Inicializa el proceso de crafteo con cantidad y ciclos
static func WriteInitCraftingAdvanced(cantidad: int, nro_por_ciclo: int) -> void:
	_log_outgoing_packet("InitCrafting", "cantidad: %d, nro_por_ciclo: %d" % [cantidad, nro_por_ciclo])
	_writer.put_u8(Enums.ClientPacketID.ClientInitCrafting)
	_writer.put_32(cantidad)
	_writer.put_16(nro_por_ciclo)

static func WriteHome() -> void:
	_log_outgoing_packet("Home")
	_writer.put_u8(Enums.ClientPacketID.ClientHome) 

static func WritePing() -> void:
	_log_outgoing_packet("Ping")
	_writer.put_u8(Enums.ClientPacketID.ClientPing)
	# El tiempo se registrará en game_context cuando sea necesario 

static func WriteTalk(text:String) -> void:
	_log_outgoing_packet("Talk", "text: " + text)
	_writer.put_u8(Enums.ClientPacketID.ClientTalk) 
	Utils.PutUnicodeString(_writer, text)

static func WriteYell(text:String) -> void:
	_log_outgoing_packet("Yell", "text: " + text)
	_writer.put_u8(Enums.ClientPacketID.ClientYell)
	Utils.PutUnicodeString(_writer, text)

static func WriteWhisper(receiver:String, text:String) -> void:
	_log_outgoing_packet("Whisper", "receiver: " + receiver + ", text: " + text)
	_writer.put_u8(Enums.ClientPacketID.ClientWhisper)
	Utils.PutUnicodeString(_writer, receiver)
	Utils.PutUnicodeString(_writer, text)

#static func WriteSpellInfo(slot:int) -> void:
	#_log_outgoing_packet("SpellInfo", "slot: " + str(slot))
	#_writer.put_u8(Enums.ClientPacketID.ClientSpellInfo) 
	#_writer.put_u8(slot) 

static func WriteCastSpell(slot:int) -> void:
	_log_outgoing_packet("CastSpell", "slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.ClientCastSpell) 
	_writer.put_u8(slot) 
	
static func WriteMoveSpell(upwards:bool, slot:int) -> void:
	_log_outgoing_packet("MoveSpell", "upwards: " + str(upwards) + ", slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.ClientMoveSpell) 
	_writer.put_u8(upwards) 
	_writer.put_u8(slot) 

static func WriteWarpChar(username:String, map_id:int, x:int, y:int) -> void:
	_log_outgoing_packet("WarpChar", "username: " + username + ", map_id: " + str(map_id) + ", x: " + str(x) + ", y: " + str(y))
	_writer.put_u8(Enums.ClientPacketID.ClientGMCommands) 
	_writer.put_u8(Enums.EGMCommands.WARP_CHAR) 
	Utils.PutUnicodeString(_writer, username)
	_writer.put_16(map_id) 
	_writer.put_u8(x) 
	_writer.put_u8(y) 

static func WriteRequestStats() -> void:
	_log_outgoing_packet("RequestStats")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestStats)

static func WriteRequestSkills() -> void:
	_log_outgoing_packet("RequestSkills")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestSkills)


static func WriteRequestAtributes() -> void:
	_log_outgoing_packet("RequestAtributes")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestAttributes)


static func WriteRequestMiniStats() -> void:
	_log_outgoing_packet("RequestMiniStats")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestMiniStats)


static func WriteRequestFame() -> void:
	_log_outgoing_packet("RequestFame")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestFame)


static func WriteModifySkills(skills: Array) -> void:
	_log_outgoing_packet("ModifySkills", "skills: " + str(skills))
	_writer.put_u8(Enums.ClientPacketID.ClientModifySkills)
	for i in range(skills.size()):
		_writer.put_u8(skills[i])

static func write_invisible() -> void:
	_log_outgoing_packet("Invisible")
	_writer.put_u8(Enums.ClientPacketID.ClientGMCommands)
	_writer.put_u8(Enums.EGMCommands.INVISIBLE)

static func change_description(description:String) -> void:
	_log_outgoing_packet("ChangeDescription", "description: " + description)
	_writer.put_u8(Enums.ClientPacketID.ClientChangeDescription)
	Utils.PutUnicodeString(_writer, description)

# Envía la alineación seleccionada para el nuevo gremio al servidor
# @param alignment_type: Tipo de alineación del gremio (ver Enums.AlignmentType)
static func WriteGuildFundation(alignment_type: int = -1) -> void:
	_log_outgoing_packet("GuildFundation", "alignment_type: " + str(alignment_type))
	_writer.put_u8(Enums.ClientPacketID.ClientGuildFundation)
	_writer.put_u8(alignment_type)

# ===== COMANDOS DE MASCOTAS =====
static func WritePetStand() -> void:
	_log_outgoing_packet("PetStand")
	_writer.put_u8(Enums.ClientPacketID.ClientPetStand)


static func WritePetFollow() -> void:
	_log_outgoing_packet("PetFollow")
	_writer.put_u8(Enums.ClientPacketID.ClientPetFollow)


static func WriteReleasePet() -> void:
	_log_outgoing_packet("ReleasePet")
	_writer.put_u8(Enums.ClientPacketID.ClientReleasePet)


# ===== COMANDOS DE ENTRENAMIENTO Y DESCANSO =====
static func WriteTrainList() -> void:
	_log_outgoing_packet("TrainList")
	_writer.put_u8(Enums.ClientPacketID.ClientTrainList)


static func WriteSpawnCreature(creature_index: int) -> void:
	_log_outgoing_packet("SpawnCreature", "creature_index: " + str(creature_index))
	_writer.put_u8(Enums.ClientPacketID.ClientGMCommands)
	_writer.put_u8(Enums.EGMCommands.SPAWN_CREATURE)
	_writer.put_16(creature_index)


static func WriteRest() -> void:
	_log_outgoing_packet("Rest")
	_writer.put_u8(Enums.ClientPacketID.ClientRest)


# ===== COMANDOS DE INFORMACIÓN =====
static func WriteConsultation() -> void:
	_log_outgoing_packet("Consultation")
	_writer.put_u8(Enums.ClientPacketID.ClientConsultation)


static func WriteHelp() -> void:
	_log_outgoing_packet("Help")
	_writer.put_u8(Enums.ClientPacketID.ClientHelp)


static func WriteEnlist() -> void:
	_log_outgoing_packet("Enlist")
	_writer.put_u8(Enums.ClientPacketID.ClientEnlist)


static func WriteInformation() -> void:
	_log_outgoing_packet("Information")
	_writer.put_u8(Enums.ClientPacketID.ClientInformation)


static func WriteReward() -> void:
	_log_outgoing_packet("Reward")
	_writer.put_u8(Enums.ClientPacketID.ClientReward)


static func WriteRequestMOTD() -> void:
	_log_outgoing_packet("RequestMOTD")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestMOTD)


#static func WriteUpTime() -> void:
	#_log_outgoing_packet("UpTime")
	#_writer.put_u8(Enums.ClientPacketID.ClientUptime)


# ===== COMANDOS DE PARTY =====
static func WritePartyLeave() -> void:
	_log_outgoing_packet("PartyLeave")
	_writer.put_u8(Enums.ClientPacketID.ClientPartyLeave)


static func WritePartyCreate() -> void:
	_log_outgoing_packet("PartyCreate")
	_writer.put_u8(Enums.ClientPacketID.ClientPartyCreate)


static func WritePartyJoin() -> void:
	_log_outgoing_packet("PartyJoin")
	_writer.put_u8(Enums.ClientPacketID.ClientPartyJoin)


static func WriteShareNpc() -> void:
	_log_outgoing_packet("ShareNpc")
	_writer.put_u8(Enums.ClientPacketID.ClientShareNpc)


static func WriteStopSharingNpc() -> void:
	_log_outgoing_packet("StopSharingNpc")
	_writer.put_u8(Enums.ClientPacketID.ClientStopSharingNpc)


static func WritePartyKick(nickname:String) -> void:
	_log_outgoing_packet("PartyKick", "nickname: " + nickname)
	_writer.put_u8(Enums.ClientPacketID.ClientPartyKick)
	Utils.PutUnicodeString(_writer, nickname)


static func WritePartySetLeader(nickname:String) -> void:
	_log_outgoing_packet("PartySetLeader", "nickname: " + nickname)
	_writer.put_u8(Enums.ClientPacketID.ClientPartySetLeader)
	Utils.PutUnicodeString(_writer, nickname)


static func WritePartyAcceptMember(nickname:String) -> void:
	_log_outgoing_packet("PartyAcceptMember", "nickname: " + nickname)
	_writer.put_u8(Enums.ClientPacketID.ClientPartyAcceptMember)
	Utils.PutUnicodeString(_writer, nickname)


# ===== COMANDOS DE ENCUESTAS Y MENSAJES =====
static func WriteInquiry() -> void:
	_log_outgoing_packet("Inquiry")
	_writer.put_u8(Enums.ClientPacketID.ClientInquiry)


static func WriteInquiryVote(vote:int) -> void:
	_log_outgoing_packet("InquiryVote", "vote: " + str(vote))
	_writer.put_u8(Enums.ClientPacketID.ClientInquiryVote)
	_writer.put_u8(vote)


static func WriteGuildMessage(message:String) -> void:
	_log_outgoing_packet("GuildMessage", "message: " + message)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildMessage)
	Utils.PutUnicodeString(_writer, message)


static func WritePartyMessage(message:String) -> void:
	_log_outgoing_packet("PartyMessage", "message: " + message)
	_writer.put_u8(Enums.ClientPacketID.ClientPartyMessage)
	Utils.PutUnicodeString(_writer, message)


static func WriteCentinelReport(code:int) -> void:
	_log_outgoing_packet("CentinelReport", "code: " + str(code))
	_writer.put_u8(Enums.ClientPacketID.ClientCentinelReport)
	_writer.put_16(code)


static func WriteGuildOnline() -> void:
	_log_outgoing_packet("GuildOnline")
	_writer.put_u8(Enums.ClientPacketID.ClientGuildOnline)


static func WritePartyOnline() -> void:
	_log_outgoing_packet("PartyOnline")
	_writer.put_u8(Enums.ClientPacketID.ClientPartyOnline)


static func WriteCouncilMessage(message:String) -> void:
	_log_outgoing_packet("CouncilMessage", "message: " + message)
	_writer.put_u8(Enums.ClientPacketID.ClientCouncilMessage)
	Utils.PutUnicodeString(_writer, message)

static func WriteGuildFundate() -> void:
	_log_outgoing_packet("GuildFundate")
	_writer.put_u8(Enums.ClientPacketID.ClientGuildFundate)

static func WriteRoleMasterRequest(question:String) -> void:
	_log_outgoing_packet("RoleMasterRequest", "question: " + question)
	_writer.put_u8(Enums.ClientPacketID.ClientRoleMasterRequest)
	Utils.PutUnicodeString(_writer, question)


static func WriteGMRequest() -> void:
	_log_outgoing_packet("GMRequest")
	_writer.put_u8(Enums.ClientPacketID.ClientGMRequest)


static func WriteBugReport(description:String) -> void:
	_log_outgoing_packet("BugReport", "description: " + description)
	_writer.put_u8(Enums.ClientPacketID.ClientBugReport)
	Utils.PutUnicodeString(_writer, description)



# ===== COMANDOS DE CLAN =====
static func WriteGuildVote(nickname:String) -> void:
	_log_outgoing_packet("GuildVote", "nickname: " + nickname)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildVote)
	Utils.PutUnicodeString(_writer, nickname)


static func WritePunishments(nickname:String) -> void:
	_log_outgoing_packet("Punishments", "nickname: " + nickname)
	_writer.put_u8(Enums.ClientPacketID.ClientPunishments)
	Utils.PutUnicodeString(_writer, nickname)


# ===== COMANDOS VARIOS =====
static func WriteLeaveFaction() -> void:
	_log_outgoing_packet("LeaveFaction")
	_writer.put_u8(Enums.ClientPacketID.ClientLeaveFaction)


static func WriteDenounce(denounce_text:String) -> void:
	_log_outgoing_packet("Denounce", "denounce_text: " + denounce_text)
	_writer.put_u8(Enums.ClientPacketID.ClientDenounce)
	Utils.PutUnicodeString(_writer, denounce_text)


static func WriteChangePassword(current_password:String, new_password:String) -> void:
	_log_outgoing_packet("ChangePassword", "current_password: [HIDDEN], new_password: [HIDDEN]")
	_writer.put_u8(Enums.ClientPacketID.ClientChangePassword)
	Utils.PutUnicodeString(_writer, current_password)
	Utils.PutUnicodeString(_writer, new_password)


# ===== COMANDOS GM =====
static func WriteTeleportChar(username:String, map:int, x:int, y:int) -> void:
	_log_outgoing_packet("TeleportChar", "username: " + username + ", map: " + str(map) + ", x: " + str(x) + ", y: " + str(y))
	_writer.put_u8(Enums.ClientPacketID.ClientGMCommands)
	_writer.put_u8(Enums.EGMCommands.WARP_CHAR)
	Utils.PutUnicodeString(_writer, username)
	_writer.put_16(map)
	_writer.put_u8(x)
	_writer.put_u8(y)


static func WriteWarpMeToTarget() -> void:
	_log_outgoing_packet("WarpMeToTarget")
	_writer.put_u8(Enums.ClientPacketID.ClientGMCommands)
	_writer.put_u8(Enums.EGMCommands.WARP_ME_TO_TARGET)

# ===== COMANDOS DE CLANES (GUILD) =====

## Solicita información del líder del clan (panel de administración)
static func WriteRequestGuildLeaderInfo() -> void:
	_log_outgoing_packet("RequestGuildLeaderInfo")
	_writer.put_u8(Enums.ClientPacketID.ClientRequestGuildLeaderInfo)

## Solicita detalles de un clan específico
static func WriteGuildRequestDetails(guild_name: String) -> void:
	_log_outgoing_packet("GuildRequestDetails", "guild_name: " + guild_name)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildRequestDetails)
	Utils.PutUnicodeString(_writer, guild_name)

## Solicita información de un miembro del clan
static func WriteGuildMemberInfo(username: String) -> void:
	_log_outgoing_packet("GuildMemberInfo", "username: " + username)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildMemberInfo)
	Utils.PutUnicodeString(_writer, username)

## Actualiza las noticias del clan
static func WriteGuildUpdateNews(news: String) -> void:
	_log_outgoing_packet("GuildUpdateNews", "news: " + news)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildUpdateNews)
	Utils.PutUnicodeString(_writer, news)

## Abre elecciones en el clan
static func WriteGuildOpenElections() -> void:
	_log_outgoing_packet("GuildOpenElections")
	_writer.put_u8(Enums.ClientPacketID.ClientGuildOpenElections)

## Solicita la lista de propuestas de alianza
static func WriteGuildAlliancePropList() -> void:
	_log_outgoing_packet("GuildAlliancePropList")
	_writer.put_u8(Enums.ClientPacketID.ClientGuildAlliancePropList)

## Solicita mostrar las noticias del clan
static func WriteShowGuildNews() -> void:
	_log_outgoing_packet("ShowGuildNews")
	_writer.put_u8(Enums.ClientPacketID.ClientShowGuildNews)

## Solicita la lista de propuestas de paz
static func WriteGuildPeacePropList() -> void:
	_log_outgoing_packet("GuildPeacePropList")
	_writer.put_u8(Enums.ClientPacketID.ClientGuildPeacePropList)

## Declara guerra a otro clan
static func WriteGuildDeclareWar(guild_name: String) -> void:
	_log_outgoing_packet("GuildDeclareWar", "guild_name: " + guild_name)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildDeclareWar)
	Utils.PutUnicodeString(_writer, guild_name)

## Actualiza la URL del sitio web del clan
static func WriteGuildNewWebsite(url: String) -> void:
	_log_outgoing_packet("GuildNewWebsite", "url: " + url)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildNewWebsite)
	Utils.PutUnicodeString(_writer, url)

## Acepta un nuevo miembro en el clan
static func WriteGuildAcceptNewMember(username: String) -> void:
	_log_outgoing_packet("GuildAcceptNewMember", "username: " + username)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildAcceptNewMember)
	Utils.PutUnicodeString(_writer, username)

## Rechaza un nuevo miembro del clan
static func WriteGuildRejectNewMember(username: String, reason: String) -> void:
	_log_outgoing_packet("GuildRejectNewMember", "username: " + username + ", reason: " + reason)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildRejectNewMember)
	Utils.PutUnicodeString(_writer, username)
	Utils.PutUnicodeString(_writer, reason)

## Expulsa un miembro del clan
static func WriteGuildKickMember(username: String) -> void:
	_log_outgoing_packet("GuildKickMember", "username: " + username)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildKickMember)
	Utils.PutUnicodeString(_writer, username)

## Solicita membresía a un clan
static func WriteGuildRequestMembership(guild_name: String, application: String) -> void:
	_log_outgoing_packet("GuildRequestMembership", "guild_name: " + guild_name + ", application: " + application)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildRequestMembership)
	Utils.PutUnicodeString(_writer, guild_name)
	Utils.PutUnicodeString(_writer, application)

## Ofrece paz a otro clan
static func WriteGuildOfferPeace(guild_name: String, proposal: String) -> void:
	_log_outgoing_packet("GuildOfferPeace", "guild_name: " + guild_name + ", proposal: " + proposal)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildOfferPeace)
	Utils.PutUnicodeString(_writer, guild_name)
	Utils.PutUnicodeString(_writer, proposal)

## Ofrece alianza a otro clan
static func WriteGuildOfferAlliance(guild_name: String, proposal: String) -> void:
	_log_outgoing_packet("GuildOfferAlliance", "guild_name: " + guild_name + ", proposal: " + proposal)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildOfferAlliance)
	Utils.PutUnicodeString(_writer, guild_name)
	Utils.PutUnicodeString(_writer, proposal)

## Acepta una propuesta de alianza
static func WriteGuildAcceptAlliance(guild_name: String) -> void:
	_log_outgoing_packet("GuildAcceptAlliance", "guild_name: " + guild_name)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildAcceptAlliance)
	Utils.PutUnicodeString(_writer, guild_name)

## Rechaza una propuesta de alianza
static func WriteGuildRejectAlliance(guild_name: String) -> void:
	_log_outgoing_packet("GuildRejectAlliance", "guild_name: " + guild_name)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildRejectAlliance)
	Utils.PutUnicodeString(_writer, guild_name)

## Acepta una propuesta de paz
static func WriteGuildAcceptPeace(guild_name: String) -> void:
	_log_outgoing_packet("GuildAcceptPeace", "guild_name: " + guild_name)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildAcceptPeace)
	Utils.PutUnicodeString(_writer, guild_name)

## Rechaza una propuesta de paz
static func WriteGuildRejectPeace(guild_name: String) -> void:
	_log_outgoing_packet("GuildRejectPeace", "guild_name: " + guild_name)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildRejectPeace)
	Utils.PutUnicodeString(_writer, guild_name)

## Solicita detalles de una propuesta de alianza
static func WriteGuildAllianceDetails(guild_name: String) -> void:
	_log_outgoing_packet("GuildAllianceDetails", "guild_name: " + guild_name)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildAllianceDetails)
	Utils.PutUnicodeString(_writer, guild_name)

## Solicita detalles de una propuesta de paz
static func WriteGuildPeaceDetails(guild_name: String) -> void:
	_log_outgoing_packet("GuildPeaceDetails", "guild_name: " + guild_name)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildPeaceDetails)
	Utils.PutUnicodeString(_writer, guild_name)

## Solicita información de un solicitante al clan
static func WriteGuildRequestJoinerInfo(username: String) -> void:
	_log_outgoing_packet("GuildRequestJoinerInfo", "username: " + username)
	_writer.put_u8(Enums.ClientPacketID.ClientGuildRequestJoinerInfo)
	Utils.PutUnicodeString(_writer, username)

## Actualiza el códex del clan
static func WriteClanCodexUpdate(description: String, codex: Array) -> void:
	_log_outgoing_packet("ClanCodexUpdate", "description: " + description + ", codex_items: " + str(codex.size()))
	_writer.put_u8(Enums.ClientPacketID.ClientClanCodexUpdate)
	Utils.PutUnicodeString(_writer, description)
	for i in range(8):
		if i < codex.size():
			Utils.PutUnicodeString(_writer, codex[i])
		else:
			Utils.PutUnicodeString(_writer, "")

## Crea un nuevo clan con códex
static func WriteCreateNewGuild(description: String, clan_name: String, site: String, codex: Array) -> void:
	_log_outgoing_packet("CreateNewGuild", "clan_name: " + clan_name + ", site: " + site)
	_writer.put_u8(Enums.ClientPacketID.ClientCreateNewGuild)
	Utils.PutUnicodeString(_writer, description)
	Utils.PutUnicodeString(_writer, clan_name)
	Utils.PutUnicodeString(_writer, site)
	for i in range(8):
		if i < codex.size():
			Utils.PutUnicodeString(_writer, codex[i])
		else:
			Utils.PutUnicodeString(_writer, "")

## Mueve un item del inventario
static func WriteMoveItem(original_slot: int, new_slot: int, move_type: int = 0) -> void:
	_log_outgoing_packet("MoveItem", "original_slot: %d, new_slot: %d, move_type: %d" % [original_slot, new_slot, move_type])
	_writer.put_u8(Enums.ClientPacketID.ClientMoveItem)
	_writer.put_u8(original_slot)
	_writer.put_u8(new_slot)
	_writer.put_u8(move_type)

## Usa el macro de hechizo configurado
static func WriteUseSpellMacro() -> void:
	_log_outgoing_packet("UseSpellMacro", "")
	_writer.put_u8(Enums.ClientPacketID.ClientUseSpellMacro)

## Entrena con una criatura de la lista del maestro
static func WriteTrain(creature: int) -> void:
	_log_outgoing_packet("Train", "creature: %d" % creature)
	_writer.put_u8(Enums.ClientPacketID.ClientTrain)
	_writer.put_u8(creature)

## Toggle de navegación (requiere barco)
static func WriteNavigateToggle() -> void:
	_log_outgoing_packet("NavigateToggle", "")
	_writer.put_u8(Enums.ClientPacketID.ClientGMCommands)
	_writer.put_u8(Enums.EGMCommands.NAVIGATE_TOGGLE)

## Toggle de ocultarse
static func WriteHiding() -> void:
	_log_outgoing_packet("Hiding", "")
	_writer.put_u8(Enums.ClientPacketID.ClientGMCommands)
	_writer.put_u8(Enums.EGMCommands.HIDING)

## Mueve un item en el banco
static func WriteMoveBank(upwards: bool, slot: int) -> void:
	_log_outgoing_packet("MoveBank", "upwards: %s, slot: %d" % [upwards, slot])
	_writer.put_u8(Enums.ClientPacketID.ClientMoveBank)
	_writer.put_u8(upwards)
	_writer.put_u8(slot)

## Hace que un NPC siga al personaje
static func WriteNPCFollow() -> void:
	_log_outgoing_packet("NPCFollow", "")
	_writer.put_u8(Enums.ClientPacketID.ClientGMCommands)
	_writer.put_u8(Enums.EGMCommands.NPC_FOLLOW)

## Inicia el proceso de crafteo de herrería
static func WriteCraftBlacksmith(item: int) -> void:
	_log_outgoing_packet("CraftBlacksmith", "item: %d" % item)
	_writer.put_u8(Enums.ClientPacketID.ClientCraftBlacksmith)
	_writer.put_16(item)

## Inicia el proceso de crafteo de carpintería
static func WriteCraftCarpenter(item: int) -> void:
	_log_outgoing_packet("CraftCarpenter", "item: %d" % item)
	_writer.put_u8(Enums.ClientPacketID.ClientCraftCarpenter)
	_writer.put_16(item)
