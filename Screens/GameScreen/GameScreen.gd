extends Node
class_name GameScreen
@export var _gameInput:GameInput
@export var _gameWorld:GameWorld
@export var _camera:Camera2D

var _gameContext:GameContext = GameContext.new()
var _mainCharacterInstanceId:int = -1
var networkMessages:Array[PackedByteArray]

var _input:Dictionary[String, int] = {
	"ui_left" = Enums.Heading.West,
	"ui_right" = Enums.Heading.East,
	"ui_up" = Enums.Heading.North,
	"ui_down" = Enums.Heading.South,
}
 
func _ready() -> void: 
	ClientInterface.disconnected.connect(_OnDisconnected)
	ClientInterface.dataReceived.connect(_OnDataReceived) 
	
	_gameInput.Init(_gameContext)
	_gameInput.update_name_label(Global.username)
	
	 
func _OnDisconnected() -> void:
	pass
	
func _OnDataReceived(data:PackedByteArray) -> void: 
	networkMessages.push_back(data)

func _process(_delta: float) -> void:
	_ProccessMessages()
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
		GameProtocol.WriteWalk(heading)
		if !_gameContext.userDescansar && !_gameContext.userMeditar:
			_gameWorld.MoveCharacter(_mainCharacterInstanceId, heading)
	else:
		if character.renderer.heading != heading:
			GameProtocol.WriteChangeHeading(heading)
		  
func _CanMoveTo(x:int, y:int) -> bool:
	var map = _gameWorld.GetMapContainer()
	
	#Limites del mapa
	#If X < MinXBorder Or X > MaxXBorder Or Y < MinYBorder Or Y > MaxYBorder Then
	#    Exit Function
	#End If
	
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

#region Network
func _ProccessMessages() -> void: 
	while !networkMessages.is_empty():
		var data = networkMessages.pop_front()
		_HandleIncomingData(data) 

func _HandleIncomingData(data:PackedByteArray) -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = data
	
	while stream.get_position() < stream.get_size():
		_HandleOnePacket(stream)
 
func _HandleOnePacket(stream:StreamPeerBuffer) -> void:
	var packetId = stream.get_u8()
	#var name = Enums.ServerPacketID.keys()[packetId]
	#pcg.append(name)
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
		Enums.ServerPacketID.PlayWave:
			_HandlePlayWave(PlayWave.new(stream))
		Enums.ServerPacketID.AreaChanged:
			_HandleAreaChanged(AreaChanged.new(stream))
		Enums.ServerPacketID.ObjectCreate:
			_HandleObjectCreate(ObjectCreate.new(stream))
		Enums.ServerPacketID.ObjectDelete:
			_HandleObjectDelete(ObjectDelete.new(stream))
		Enums.ServerPacketID.BlockPosition:
			_HandleBlockPosition(BlockPosition.new(stream))
		Enums.ServerPacketID.CharacterCreate:
			_HandleCharacterCreate(CharacterCreate.new(stream))
		Enums.ServerPacketID.CharacterMove:
			_HandleCharacterMove(CharacterMove.new(stream))
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
			_HandleLogged(Logged.new(stream))
		Enums.ServerPacketID.RainToggle:
			pass
		Enums.ServerPacketID.RemoveDialogs:
			_HandleRemoveDialogs()
		Enums.ServerPacketID.UpdateSta:
			_HandleUpdateSta(UpdateSta.new(stream))
		Enums.ServerPacketID.ConsoleMsg:
			_HandleConsoleMessage(ConsoleMessage.new(stream))
		Enums.ServerPacketID.RemoveCharDialog:
			_HandleRemoveCharDialog(RemoveCharDialog.new(stream))
		Enums.ServerPacketID.CharacterRemove:
			_HandleCharacterRemove(CharacterRemove.new(stream))
		Enums.ServerPacketID.UpdateHP:
			_HandleUpdateHP(UpdateHP.new(stream))
		Enums.ServerPacketID.CharacterChange:
			_HandleCharacterChange(CharacterChange.new(stream))
		Enums.ServerPacketID.ForceCharMove:
			_HandleForceCharMove(ForceCharMove.new(stream))
		Enums.ServerPacketID.PosUpdate:
			_HandlePosUpdate(PosUpdate.new(stream))
		Enums.ServerPacketID.UpdateTagAndStatus:
			_HandleUpdateTagAndStatus(UpdateTagAndStatus.new(stream))
		Enums.ServerPacketID.ChatOverHead:
			_HandleChatOverHead(ChatOverHead.new(stream))
		Enums.ServerPacketID.ChangeNPCInventorySlot:
			_HandleChangeNPCInventorySlot(ChangeNPCInventorySlot.new(stream))
		Enums.ServerPacketID.CommerceInit:
			_HandleCommerceInit()
		Enums.ServerPacketID.CommerceEnd:
			_HandleCommerceEnd()
		Enums.ServerPacketID.TradeOK:
			pass
		Enums.ServerPacketID.BankOK:
			pass
		Enums.ServerPacketID.ChangeBankSlot:
			_HandleChangeBankSlot(ChangeBankSlot.new(stream))
		Enums.ServerPacketID.BankInit:
			_HandleBankInit(BankInit.new(stream))
		Enums.ServerPacketID.BankEnd:
			_HandleBankEnd()
		Enums.ServerPacketID.UpdateBankGold:
			_HandleUpdateBankGold(UpdateBankGold.new(stream))
		Enums.ServerPacketID.UpdateGold:
			_HandleUpdateGold(UpdateGold.new(stream))
		Enums.ServerPacketID.UpdateStrenght:
			_HandleUpdateStrenght(UpdateStrenght.new(stream))
		Enums.ServerPacketID.UpdateDexterity:
			_HandleUpdateDexterity(UpdateDexterity.new(stream))
		Enums.ServerPacketID.Pong:
			_HandlePong()
		Enums.ServerPacketID.ShowMessageBox:
			_HandleShowMessageBox(ShowMessageBox.new(stream))
		Enums.ServerPacketID.UpdateExp:
			_HandelUpdateExp(UpdateExp.new(stream))
		_:
			print(name)
			
func _HandelUpdateExp(p:UpdateExp) -> void:
	_gameInput.SetExperience(p.experience)
			
func _HandleShowMessageBox(p:ShowMessageBox) -> void:
	Utils.ShowAlertDialog("Server", p.message, get_parent())

func _HandlePong() -> void:
	print("Ping: %dms" % (Time.get_ticks_msec() - _gameContext.pingTime))
	_gameContext.pingTime = 0


func _HandleUpdateDexterity(p:UpdateDexterity) -> void:
	_gameInput.update_agility_label(p.dexterity)

	
func _HandleUpdateStrenght(p:UpdateStrenght) -> void:
	_gameInput.update_strength_label(p.strenght)


func _HandleUpdateGold(p:UpdateGold) -> void:
	_gameInput.update_gold_label(p.gold)


func _HandleUpdateBankGold(p:UpdateBankGold) -> void:
	_gameInput.SetBankGold(p.gold)

func _HandleChangeBankSlot(p:ChangeBankSlot) -> void:
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
	
	var itemStack = ItemStack.new(p.amount, false, item)
	_gameContext.bankInventory.SetSlot(p.slot -1, itemStack)

func _HandleCommerceInit() -> void:
	_gameInput.OpenMerchant()
	
func _HandleCommerceEnd() -> void:
	_gameInput.CloseMerchant()
	
func _HandleBankInit(p:BankInit) -> void:
	_gameInput.OpenBank()
	_gameInput.SetBankGold(p.gold)

func _HandleBankEnd() -> void:
	_gameInput.CloseBank()

func _HandleChangeNPCInventorySlot(p:ChangeNPCInventorySlot) -> void:
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
	
	var itemStack = ItemStack.new(p.amount, false, item)
	_gameContext.merchantInventory.SetSlot(p.slot -1, itemStack)
		
func _HandleChatOverHead(p:ChatOverHead) -> void:
	var character = _gameWorld.GetCharacter(p.charIndex)
	if character:
		character.Say(p.chat, p.color)
				
func _HandleUpdateTagAndStatus(p:UpdateTagAndStatus) -> void:
	var character = _gameWorld.GetCharacter(p.charIndex)
	if character:
		character.SetCharacterName(p.userTag)
		character.SetCharacterNameColor(Utils.GetNickColor(p.nickColor, character.priv))

func _HandlePosUpdate(p:PosUpdate) -> void:
	var character = _gameWorld.GetCharacter(_mainCharacterInstanceId)
	if character:
		character.StopMoving()
		character.gridPosition = Vector2i(p.x, p.y)
		character.position = Vector2((p.x - 1) * 32, (p.y - 1) * 32) + Vector2(16, 32);

func _HandleForceCharMove(p:ForceCharMove) -> void:
	var character = _gameWorld.GetCharacter(_mainCharacterInstanceId)
	if character:
		character.StopMoving()
		_gameWorld.MoveCharacter(_mainCharacterInstanceId, p.heading)

func _HandleLogged(p:Logged) -> void:
	pass

func _HandleCharacterChange(p:CharacterChange) -> void:
	var character = _gameWorld.GetCharacter(p.charIndex)
	if character == null: return
	
	character.renderer.body = p.body
	character.renderer.head = p.head
	character.renderer.helmet = p.helmet
	character.renderer.weapon = p.weapon
	character.renderer.shield = p.shield
	character.renderer.heading = p.heading
	
func _HandleUpdateHP(p:UpdateHP) -> void:
	pass

func _HandleCharacterRemove(p:CharacterRemove) -> void:
	_gameWorld.DeleteCharacter(p.charIndex)

func _HandleRemoveCharDialog(p:RemoveCharDialog) -> void:
	var character = _gameWorld.GetCharacter(p.charIndex)
	if character:
		character.Say("", Color.WHITE)

func _HandleConsoleMessage(p:ConsoleMessage) -> void:
	_gameInput.ShowConsoleMessage(p.message, GameAssets.FontDataList[p.fontIndex])

func _HandleUpdateSta(p:UpdateSta) -> void:
	pass

func _HandleRemoveDialogs() -> void:
	pass

func _HandleLevelUp(p:LevelUp) -> void:
	pass

func _HandleSendSkills(p:SendSkills) -> void:
	pass
				
func _HandleGuildChat(p:GuildChat) -> void:
	pass


func _HandleUpdateStrengthAndDexterity(p:UpdateStrengthAndDexterity) -> void:
	_gameInput.update_agility_label(p.dexterity)
	_gameInput.update_strength_label(p.strength)


func _HandleUpdateHungerAndThirst(p:UpdateHungerAndThirst) -> void:
	pass


func _HandleUpdateUserStats(p:UpdateUserStats) -> void: 
	_gameInput.update_gold_label(p.gold)
	_gameInput.update_level_label(p.elv)


func _HandleUserCharIndexInServer(p:UserCharIndexInServer) -> void:
	_mainCharacterInstanceId = p.charIndex

func _HandleCreateFx(p:CreateFx) -> void:
	pass

func _HandleSetInvisible(p:SetInvisible) -> void:
	var character = _gameWorld.GetCharacter(p.charIndex)
	if character:
		character.SetCharacterInvisible(!p.invisible)
				
func _HandleCharacterCreate(p:CharacterCreate) -> void:
	var privileges = p.privileges
	if privileges != 0:
		if (privileges & Enums.PlayerType.ChaosCouncil) != 0 && (privileges & Enums.PlayerType.User) == 0:
			privileges  = privileges ^ Enums.PlayerType.ChaosCouncil
		
		if (privileges & Enums.PlayerType.RoyalCouncil) != 0 && (privileges & Enums.PlayerType.User) == 0:
			privileges  = privileges ^ Enums.PlayerType.RoyalCouncil
		
		if (privileges & Enums.PlayerType.RoleMaster) != 0:
			privileges = Enums.PlayerType.RoleMaster
		
		privileges = log(privileges) / log(2)
		
	p.privileges = privileges
	_gameWorld.CreateCharacter(p)

func _HandleCharacterMove(p:CharacterMove) -> void:
	var character = _gameWorld.GetCharacter(p.charIndex)
	if character == null:
		return
		
	var addX = p.x - character.gridPosition.x
	var addY = p.y - character.gridPosition.y
	
	var heading = Enums.Heading.South
	if Utils.Sgn(addX) == 1:
		heading = Enums.Heading.East;
	elif Utils.Sgn(addX) == -1:
		heading = Enums.Heading.West;
	elif Utils.Sgn(addY) == 1:
		heading = Enums.Heading.South;
	elif Utils.Sgn(addY) == -1:
		heading = Enums.Heading.North;
		
	_gameWorld.MoveCharacter(p.charIndex, heading)

func _HandleBlockPosition(p:BlockPosition) -> void:
	if p.blocked:
		_gameWorld.GetMapContainer().BlockTile(p.x -1, p.y - 1)
	else:
		_gameWorld.GetMapContainer().UnblockTile(p.x -1, p.y - 1)

func _HandleObjectCreate(p:ObjectCreate) -> void:
	_gameWorld.AddObject(p.grhId, p.x, p.y)

func _HandleObjectDelete(p:ObjectDelete) -> void:
	_gameWorld.DeleteObject(p.x, p.y)

func _HandleAreaChanged(_p:AreaChanged) -> void:
	pass

func _HandlePlayMidi(p:PlayMidi) -> void:
	pass
	
func _HandlePlayWave(p:PlayWave) -> void:
	AudioManager.PlayAudio(p.wave)

func _HandleChangeMap(p:ChangeMap) -> void:
	_gameWorld.SwitchMap(p.mapId)
		
func _HandleChangeSpellSlot(p:ChangeSpellSlot) -> void:
	_gameInput.SetSpellName(p.slot -1, p.name)

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
	_gameInput.update_equipment_label(p.slot - 1, itemStack)

func _HandleMultiMessage(p:MultiMessage) -> void:
	match p.index:
		Enums.Messages.SafeModeOn:
			_gameInput.ShowConsoleMessage(">>SEGURO ACTIVADO<<", FontData.new(Color.GREEN, true))
		Enums.Messages.SafeModeOff:
			_gameInput.ShowConsoleMessage(">>SEGURO DESACTIVADO<<", FontData.new(Color.RED, true))
		Enums.Messages.ResuscitationSafeOn:
			_gameInput.ShowConsoleMessage("SEGURO DE RESURRECCION ACTIVADO", FontData.new(Color.GREEN, true))
		Enums.Messages.ResuscitationSafeOff:
			_gameInput.ShowConsoleMessage("SEGURO DE RESURRECCION DESACTIVADO", FontData.new(Color.RED, true))
		Enums.Messages.DontSeeAnything:
			_gameInput.ShowConsoleMessage("No ves nada interesante.", FontData.new(Color.from_rgba8(65, 190, 156)))
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
			_gameInput.ShowConsoleMessage("¡Has perdido nobleza y ganado criminalidad! Sigue así y las tropas te perseguirán.", FontData.new(Color.RED))
		Enums.Messages.CantUseWhileMeditating:
			_gameInput.ShowConsoleMessage("¡Estás meditando! Debes dejar de meditar para usar objetos.", FontData.new(Color.RED))
		Enums.Messages.NPCHitUser:
			match p.arg1:
				Consts.bCabeza:
					_gameInput.ShowConsoleMessage("¡¡La criatura te ha pegado en la cabeza por " + str(p.arg2) + "!!", FontData.new(Color.RED, true))
				Consts.bBrazoIzquierdo:
					_gameInput.ShowConsoleMessage("¡¡La criatura te ha pegado el brazo izquierdo por " + str(p.arg2) + "!!", FontData.new(Color.RED, true))
				Consts.bBrazoDerecho:
					_gameInput.ShowConsoleMessage("¡¡La criatura te ha pegado el brazo derecho por " + str(p.arg2) + "!!", FontData.new(Color.RED, true))
				Consts.bPiernaIzquierda:
					_gameInput.ShowConsoleMessage("¡¡La criatura te ha pegado la pierna izquierda por " + str(p.arg2) + "!!", FontData.new(Color.RED, true))
				Consts.bPiernaDerecha:
					_gameInput.ShowConsoleMessage("¡¡La criatura te ha pegado la pierna derecha por " + str(p.arg2) + "!!", FontData.new(Color.RED, true))
				Consts.bTorso:
					_gameInput.ShowConsoleMessage("¡¡La criatura te ha pegado en el torso por " + str(p.arg2) + "!!", FontData.new(Color.RED, true))
		Enums.Messages.UserHitNPC:
			_gameInput.ShowConsoleMessage("¡¡Le has pegado a la criatura por " + str(p.arg1) + "!!", FontData.new(Color.RED, true))
		Enums.Messages.UserAttackedSwing:
			_gameInput.ShowConsoleMessage("¡¡ " + _gameWorld.GetCharacter(p.arg1).GetCharacterName() + " te atacó y falló!!", FontData.new(Color.RED, true))
		Enums.Messages.UserHittedByUser:
			var charName = _gameWorld.GetCharacter(p.arg1).GetCharacterName() 
			_gameInput.ShowConsoleMessage(Consts.MessageUserHittedByUser[p.arg2].format([charName, p.arg3]), FontData.new(Color.RED)) 
		Enums.Messages.UserHittedUser:
			var charName = _gameWorld.GetCharacter(p.arg1).GetCharacterName()
			_gameInput.ShowConsoleMessage(Consts.MessageUserHittedUser[p.arg2].format([charName, p.arg3]), FontData.new(Color.RED)) 
		Enums.Messages.WorkRequestTarget:
			_gameContext.usingSkill = p.arg1
			_gameInput.ShowConsoleMessage(Consts.MessageWorkRequestTarget[p.arg1], FontData.new(Color.from_rgba8(100, 100, 120))) 
		Enums.Messages.HaveKilledUser:
			var charName = _gameWorld.GetCharacter(p.arg1).GetCharacterName()
			_gameInput.ShowConsoleMessage("Has matado a {0}!".format([charName]), FontData.new(Color.RED, true)) 
			_gameInput.ShowConsoleMessage("Has ganado {0} puntos de experiencia.".format([p.arg2]), FontData.new(Color.RED, true)) 
		Enums.Messages.UserKill:
			var charName = _gameWorld.GetCharacter(p.arg1).GetCharacterName()
			_gameInput.ShowConsoleMessage("{0} te ha matado!".format([charName]), FontData.new(Color.RED, true)) 
		Enums.Messages.Home:
			var distance = p.arg1
			var time = p.arg2
			var home = p.string_arg1
			var message = ""
			
			if time >= 60:
				if time % 60 == 0:
					message = "{0} minutos.".format([time / 60])
				else:
					message = "{0} minutos y {1} segundos.".format([int(time / 60), time % 60]) 
			else:
				message = "{0} segundos.".format([time])
			_gameInput.ShowConsoleMessage("Te encuentras a {0} mapas de la {1}, este viaje durará {2}".format([distance, home, message]), FontData.new(Color.RED, true)) 
			_gameContext.traveling = true
		Enums.Messages.FinishHome:
			_gameInput.ShowConsoleMessage("Has llegado a tu hogar. El viaje ha finalizado.", FontData.new(Color.WHITE)) 
			_gameContext.traveling = false
		Enums.Messages.CancelHome:
			_gameInput.ShowConsoleMessage("Tu viaje ha sido cancelado.", FontData.new(Color.RED)) 
			_gameContext.traveling = false
	
func _FlushData() -> void:
	if !GameProtocol.IsEmpty(): 
		ClientInterface.Send(GameProtocol.Flush())
#endregion


func _OnPingTimerTimeout() -> void:
	if _gameContext.pingTime != 0: return
	GameProtocol.WritePing()
	_FlushData()
	_gameContext.pingTime = Time.get_ticks_msec()
