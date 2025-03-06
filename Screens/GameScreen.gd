extends Node
class_name GameScreen
@export var _gameInput:GameInput

var _gameContext:GameContext = GameContext.new()

func _ready() -> void:
	ClientInterface.connected.connect(_OnConnected)
	ClientInterface.disconnected.connect(_OnDisconnected)
	ClientInterface.dataReceived.connect(_OnDataReceived)
	
	ClientInterface.ConnectToHost("127.0.0.1", 7666)
	_gameInput.Init(_gameContext)
	
func _OnConnected() -> void:
	GameProtocol.WriteLoginExistingCharacter("shak", "123")
	
func _OnDisconnected() -> void:
	pass
	
func _OnDataReceived(data:PackedByteArray) -> void:
	_HandleIncomingData(data)

func _process(_delta: float) -> void:
	FlushData()
 
#region Network
func _HandleIncomingData(data:PackedByteArray) -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = data
	
	while stream.get_position() < stream.get_size(): 
		_HandleOnePacket(stream)
	
func _HandleOnePacket(stream:StreamPeerBuffer) -> void:
		var packetId = stream.get_u8()
		var name = Enums.ServerPacketID.keys()[packetId] 
		match packetId: 
			Enums.ServerPacketID.MultiMessage:
				_HandleMultiMessage(MultiMessage.new(stream))
			Enums.ServerPacketID.ChangeInventorySlot:
				_HandleChangeInventorySlot(ChangeInventorySlot.new(stream))
			Enums.ServerPacketID.ChangeSpellSlot:
				_HandleChangeSpellSlot(ChangeSpellSlot.new(stream))
			Enums.ServerPacketID.UserIndexInServer:
				UserIndexInServer.new(stream)
			Enums.ServerPacketID.ChangeMap:
				_HandleChangeMap(ChangeMap.new(stream))
			Enums.ServerPacketID.PlayMIDI:
				_HandlePlayMidi(PlayMidi.new(stream))
			Enums.ServerPacketID.AreaChanged:
				_HandleAreaChanged(AreaChanged.new(stream))
			Enums.ServerPacketID.ObjectCreate:
				_HandleObjectCreate(ObjectCreate.new(stream))
			Enums.ServerPacketID.BlockPosition:
				_HandleBlockPosition(BlockPosition.new(stream))
			Enums.ServerPacketID.CharacterCreate:
				_HandleCharacterCreate(CharacterCreate.new(stream))
			Enums.ServerPacketID.SetInvisible:
				_HandleSetInvisible(SetInvisible.new(stream))
			Enums.ServerPacketID.CreateFX:
				_HandleCreateFx(CreateFx.new(stream))
			Enums.ServerPacketID.UserCharIndexInServer:
				_HandleUserCharIndexInServer(UserCharIndexInServer.new(stream))
			Enums.ServerPacketID.UpdateUserStats:
				_HandleUpdateUserStats(UpdateUserStats.new(stream))
			Enums.ServerPacketID.UpdateHungerAndThirst:
				_HandleUpdateHungerAndThirst(UpdateHungerAndThirst.new(stream))
			Enums.ServerPacketID.UpdateStrenghtAndDexterity:
				_HandleUpdateStrengthAndDexterity(UpdateStrengthAndDexterity.new(stream))
			Enums.ServerPacketID.GuildChat:
				_HandleGuildChat(GuildChat.new(stream))
			Enums.ServerPacketID.SendSkills:
				_HandleSendSkills(SendSkills.new(stream))
			Enums.ServerPacketID.LevelUp:
				_HandleLevelUp(LevelUp.new(stream))
			Enums.ServerPacketID.Logged:
				pass
			Enums.ServerPacketID.RemoveDialogs:
				_HandleRemoveDialogs()
			_:
				print(name)

func _HandleRemoveDialogs() -> void:
	pass

func _HandleLevelUp(p:LevelUp) -> void:
	pass

func _HandleSendSkills(p:SendSkills) -> void:
	pass
				
func _HandleGuildChat(p:GuildChat) -> void:
	pass

func _HandleUpdateStrengthAndDexterity(p:UpdateStrengthAndDexterity) -> void:
	pass	

func _HandleUpdateHungerAndThirst(p:UpdateHungerAndThirst) -> void:
	pass

func _HandleUpdateUserStats(p:UpdateUserStats) -> void:
	pass

func _HandleUserCharIndexInServer(p:UserCharIndexInServer) -> void:
	pass

func _HandleCreateFx(p:CreateFx) -> void:
	pass

func _HandleSetInvisible(p:SetInvisible) -> void:
	pass
				
func _HandleCharacterCreate(p:CharacterCreate) -> void:
	pass
				
func _HandleBlockPosition(p:BlockPosition) -> void:
	pass

func _HandleObjectCreate(p:ObjectCreate) -> void:
	pass

func _HandleAreaChanged(p:AreaChanged) -> void:
	pass

func _HandlePlayMidi(p:PlayMidi) -> void:
	pass

func _HandleChangeMap(p:ChangeMap) -> void:
	pass
		
func _HandleChangeSpellSlot(p:ChangeSpellSlot) -> void:
	pass

func _HandleChangeInventorySlot(p:ChangeInventorySlot) -> void:
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
	
	var itemStack = ItemStack.new(p.amount, p.equipped, item)
	_gameContext.playerInventory.SetSlot(p.slot -1, itemStack)

func _HandleMultiMessage(p:MultiMessage) -> void:
	pass

func FlushData() -> void:
	var data = GameProtocol.Flush()
	ClientInterface.Send(data)
#endregion
