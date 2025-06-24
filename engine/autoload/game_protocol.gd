extends Node
class_name GameProtocol

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
	_writer.clear() 
	return data
	
static func IsEmpty() -> bool:
	return _writer.get_size() == 0

static func Clear() -> void:
	_writer.clear()

static func WriteLoginExistingCharacter(username:String, password:String) -> void:
	_log_outgoing_packet("LoginExistingCharacter", "username: " + username + ", password: " + password)
	_writer.put_u8(Enums.ClientPacketID.LoginExistingChar)
	Utils.PutUnicodeString(_writer, username)
	Utils.PutUnicodeString(_writer, password)
	_writer.put_u8(0)
	_writer.put_u8(13)
	_writer.put_u8(0)
	
static func WriteLoginNewChar(username:String, password:String, email:String, job:int, race:int, gender:int, home:int, head:int) -> void:
	_log_outgoing_packet("LoginNewChar", "username: " + username + ", password: " + password + ", email: " + email + ", job: " + str(job) + ", race: " + str(race) + ", gender: " + str(gender) + ", home: " + str(home) + ", head: " + str(head))
	_writer.put_u8(Enums.ClientPacketID.LoginNewChar)
	Utils.PutUnicodeString(_writer, username)
	Utils.PutUnicodeString(_writer, password)
	_writer.put_u8(0)
	_writer.put_u8(13)
	_writer.put_u8(0)
	
	_writer.put_u8(race)
	_writer.put_u8(gender)
	_writer.put_u8(job)
	_writer.put_16(head)
	Utils.PutUnicodeString(_writer, email)
	_writer.put_u8(home)
	
static func WriteThrowDice() -> void:
	_log_outgoing_packet("ThrowDices")
	_writer.put_u8(Enums.ClientPacketID.ThrowDices)
	
static func WriteWalk(heading:int) -> void:
	_log_outgoing_packet("Walk", "heading: " + str(heading))
	_writer.put_u8(Enums.ClientPacketID.Walk) 
	_writer.put_u8(heading)
	
static func WriteChangeHeading(heading:int) -> void:
	_log_outgoing_packet("ChangeHeading", "heading: " + str(heading))
	_writer.put_u8(Enums.ClientPacketID.ChangeHeading) 
	_writer.put_u8(heading) 
	
static func WriteEquipItem(slot:int) -> void:
	_log_outgoing_packet("EquipItem", "slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.EquipItem) 
	_writer.put_u8(slot) 
	
static func WriteUseItem(slot:int) -> void:
	_log_outgoing_packet("UseItem", "slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.UseItem) 
	_writer.put_u8(slot) 
	
static func WriteQuit() -> void:
	_log_outgoing_packet("Quit")
	_writer.put_u8(Enums.ClientPacketID.Quit)
	
static func WriteSafeToggle() -> void:
	_log_outgoing_packet("SafeToggle")
	_writer.put_u8(Enums.ClientPacketID.SafeToggle)
	
static func WriteResuscitationToggle() -> void:
	_log_outgoing_packet("ResuscitationSafeToggle")
	_writer.put_u8(Enums.ClientPacketID.ResuscitationSafeToggle)
	
static func WriteDrop(slot:int, quantity:int) -> void:
	_log_outgoing_packet("Drop", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.Drop) 
	_writer.put_u8(slot) 
	_writer.put_16(quantity) 
	
static func WriteDoubleClick(x:int, y:int) -> void:
	_log_outgoing_packet("DoubleClick", "x: " + str(x) + ", y: " + str(y))
	_writer.put_u8(Enums.ClientPacketID.DoubleClick) 
	_writer.put_u8(x)
	_writer.put_u8(y) 

static func WriteLeftClick(x:int, y:int) -> void:
	_log_outgoing_packet("LeftClick", "x: " + str(x) + ", y: " + str(y))
	_writer.put_u8(Enums.ClientPacketID.LeftClick) 
	_writer.put_u8(x)
	_writer.put_u8(y) 
	
static func WriteWorkLeftClick(x:int, y:int, skill:int) -> void:
	_log_outgoing_packet("WorkLeftClick", "x: " + str(x) + ", y: " + str(y) + ", skill: " + str(skill))
	_writer.put_u8(Enums.ClientPacketID.WorkLeftClick) 
	_writer.put_u8(x)
	_writer.put_u8(y) 
	_writer.put_u8(skill) 
	
static func WriteCommerceEnd() -> void:
	_log_outgoing_packet("CommerceEnd")
	_writer.put_u8(Enums.ClientPacketID.CommerceEnd) 
	
static func WriteCommerceSell(slot:int, quantity:int) -> void:
	_log_outgoing_packet("CommerceSell", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.CommerceSell) 
	_writer.put_u8(slot)
	_writer.put_16(quantity) 

static func WriteCommerceBuy(slot:int, quantity:int) -> void:
	_log_outgoing_packet("CommerceBuy", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.CommerceBuy) 
	_writer.put_u8(slot)
	_writer.put_16(quantity) 

static func WriteCommerceStart() -> void:
	_log_outgoing_packet("CommerceStart")
	_writer.put_u8(Enums.ClientPacketID.CommerceStart)

static func WriteBankStart() -> void:
	_log_outgoing_packet("BankStart")
	_writer.put_u8(Enums.ClientPacketID.BankStart)
	
static func WriteBankEnd() -> void:
	_log_outgoing_packet("BankEnd")
	_writer.put_u8(Enums.ClientPacketID.BankEnd)  
	
static func WriteBankExtractItem(slot:int, quantity:int) -> void:
	_log_outgoing_packet("BankExtractItem", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.BankExtractItem) 
	_writer.put_u8(slot)
	_writer.put_16(quantity) 

static func WriteBankDepositItem(slot:int, quantity:int) -> void:
	_log_outgoing_packet("BankDeposit", "slot: " + str(slot) + ", quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.BankDeposit) 
	_writer.put_u8(slot)
	_writer.put_16(quantity) 
	
static func WriteBankDepositGold(quantity:int) -> void:
	_log_outgoing_packet("BankDepositGold", "quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.BankDepositGold) 
	_writer.put_32(quantity)
	
static func WriteBankExtractGold(quantity:int) -> void:
	_log_outgoing_packet("BankExtractGold", "quantity: " + str(quantity))
	_writer.put_u8(Enums.ClientPacketID.BankExtractGold) 
	_writer.put_32(quantity)

static func WriteRequestAccountState() -> void:
	_log_outgoing_packet("RequestAccountState")
	_writer.put_u8(Enums.ClientPacketID.RequestAccountState)

static func WriteOnline() -> void:
	_log_outgoing_packet("Online")
	_writer.put_u8(Enums.ClientPacketID.Online)

static func WriteGamble(amount:int) -> void:
	_log_outgoing_packet("Gamble", "amount: " + str(amount))
	_writer.put_u8(Enums.ClientPacketID.Gamble)
	_writer.put_16(amount)

static func WriteResucitate() -> void:
	_log_outgoing_packet("Resucitate")
	_writer.put_u8(Enums.ClientPacketID.Resucitate)

static func WriteGuildLeave() -> void:
	_log_outgoing_packet("GuildLeave")
	_writer.put_u8(Enums.ClientPacketID.GuildLeave)

static func WriteHeal() -> void:
	_log_outgoing_packet("Heal")
	_writer.put_u8(Enums.ClientPacketID.Heal)

static func WriteAttack() -> void:
	_log_outgoing_packet("Attack")
	_writer.put_u8(Enums.ClientPacketID.Attack)

static func WritePickup() -> void:
	_log_outgoing_packet("PickUp")
	_writer.put_u8(Enums.ClientPacketID.PickUp)
	
static func WriteRequestPositionUpdate() -> void:
	_log_outgoing_packet("RequestPositionUpdate")
	_writer.put_u8(Enums.ClientPacketID.RequestPositionUpdate)

static func WriteMeditate() -> void:
	_log_outgoing_packet("Meditate")
	_writer.put_u8(Enums.ClientPacketID.Meditate)
	
static func WriteWork(skill:int) -> void:
	_log_outgoing_packet("Work", "skill: " + str(skill))
	_writer.put_u8(Enums.ClientPacketID.Work) 
	_writer.put_u8(skill) 

static func WriteTalk(text:String) -> void:
	_log_outgoing_packet("Talk", "text: " + text)
	_writer.put_u8(Enums.ClientPacketID.Talk) 
	Utils.PutUnicodeString(_writer, text)

static func WriteYell(text:String) -> void:
	_log_outgoing_packet("Yell", "text: " + text)
	_writer.put_u8(Enums.ClientPacketID.Yell)
	Utils.PutUnicodeString(_writer, text)

static func WriteWhisper(receiver:String, text:String) -> void:
	_log_outgoing_packet("Whisper", "receiver: " + receiver + ", text: " + text)
	_writer.put_u8(Enums.ClientPacketID.Whisper)
	Utils.PutUnicodeString(_writer, receiver)
	Utils.PutUnicodeString(_writer, text)

static func WritePing() -> void:
	_log_outgoing_packet("Ping")
	_writer.put_u8(Enums.ClientPacketID.Ping)

static func WriteSpellInfo(slot:int) -> void:
	_log_outgoing_packet("SpellInfo", "slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.SpellInfo) 
	_writer.put_u8(slot) 

static func WriteCastSpell(slot:int) -> void:
	_log_outgoing_packet("CastSpell", "slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.CastSpell) 
	_writer.put_u8(slot) 
	
static func WriteMoveSpell(upwards:bool, slot:int) -> void:
	_log_outgoing_packet("MoveSpell", "upwards: " + str(upwards) + ", slot: " + str(slot))
	_writer.put_u8(Enums.ClientPacketID.MoveSpell) 
	_writer.put_u8(upwards) 
	_writer.put_u8(slot) 

static func WriteWarpChar(username:String, map_id:int, x:int, y:int) -> void:
	_log_outgoing_packet("WarpChar", "username: " + username + ", map_id: " + str(map_id) + ", x: " + str(x) + ", y: " + str(y))
	_writer.put_u8(Enums.ClientPacketID.GMCommands) 
	_writer.put_u8(Enums.EGMCommands.WARP_CHAR) 
	Utils.PutUnicodeString(_writer, username)
	_writer.put_16(map_id) 
	_writer.put_u8(x) 
	_writer.put_u8(y) 

static func WriteRequestStats() -> void:
	_log_outgoing_packet("RequestStats")
	_writer.put_u8(Enums.ClientPacketID.RequestStats)

static func WriteRequestSkills() -> void:
	_log_outgoing_packet("RequestSkills")
	_writer.put_u8(Enums.ClientPacketID.RequestSkills)


static func WriteModifySkills(skills: Array) -> void:
	_log_outgoing_packet("ModifySkills", "skills: " + str(skills))
	_writer.put_u8(Enums.ClientPacketID.ModifySkills)
	for i in range(skills.size()):
		_writer.put_u8(skills[i])

static func write_invisible() -> void:
	_log_outgoing_packet("Invisible")
	_writer.put_u8(Enums.ClientPacketID.GMCommands)
	_writer.put_u8(Enums.EGMCommands.INVISIBLE)

static func change_description(description:String) -> void:
	_log_outgoing_packet("ChangeDescription", "description: " + description)
	_writer.put_u8(Enums.ClientPacketID.ChangeDescription)
	Utils.PutUnicodeString(_writer, description)
