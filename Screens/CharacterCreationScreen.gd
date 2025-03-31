extends Node

@export var _usernameLineEdit:LineEdit
@export var _passwordLineEdit:LineEdit
@export var _confirmPasswordLineEdit:LineEdit
@export var _emailLineEdit:LineEdit

@export var _classOptionButton:OptionButton
@export var _raceOptionButton:OptionButton
@export var _genderOptionButton:OptionButton
@export var _homeOptionButton:OptionButton

@export var _submitButton:Button
@export var _attributeContainer:VBoxContainer

func _ready() -> void:
	ClientInterface.disconnected.connect(_OnDisconnected)
	ClientInterface.dataReceived.connect(_OnDataReceivedd) 
	
	_Init()

func _Init() -> void:
	for i in range(1, Consts.NumClases + 1):
		_classOptionButton.add_item(Consts.ClassNames[i])
	
	for i in range(1, Consts.NumRazas + 1):
		_raceOptionButton.add_item(Consts.RaceNames[i])
		
	for i in range(1, Consts.NumCiudades):
		_homeOptionButton.add_item(Consts.HomeNames[i])
		
	_ThrowDice()
  
func _OnDisconnected() -> void:
	var screen = load("uid://cd452cndcck7v").instantiate()  
	ScreenController.SwitchScreen(screen) 

func _OnDataReceivedd(data:PackedByteArray) -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = data
	
	while stream.get_position() < stream.get_size():
		var packetId = stream.get_u8()
		match packetId:
			Enums.ServerPacketID.DiceRoll:
				_HandleDiceRoll(stream.get_data(5)[1])
			Enums.ServerPacketID.ErrorMsg:
				Utils.ShowAlertDialog("Creacion de personajes", Utils.GetUnicodeString(stream), self)
			_:
				_HandleLogged(data) 
				return 
				
func _HandleLogged(data:PackedByteArray) -> void:
	var screen = load("uid://b2dyxo3826bub").instantiate() as GameScreen
	screen.networkMessages.append(data)
	
	ScreenController.SwitchScreen(screen)
	ClientInterface.dataReceived.disconnect(_OnDataReceivedd)  

func _HandleDiceRoll(collection:Array[int]) -> void:
	const names = ["Fuerza", "Agilidad", "Inteligencia", "Carisma", "Constitucion"]
	for i in collection.size():
		_attributeContainer.get_child(i).text = "{0}: {1}".format([names[i], collection[i]])
	
func _OnSubmitButtonPressed() -> void:
	if _usernameLineEdit.text.is_empty():
		Utils.ShowAlertDialog("Error", "Nombre de usuario vacio.", self)
		return

	if _usernameLineEdit.text.length() < 3 || _usernameLineEdit.text.length() > 15:
		Utils.ShowAlertDialog("Error", "el nombre del usuario tiene que tener un minimo de 3 caracteres y un maximo de 15 caracteres", self)
		return
	
	for i in _usernameLineEdit.text:
		if !Utils.LegalCharacter(i):
			Utils.ShowAlertDialog("Error", "Nombre invalido: El caracter [{0}] no esta permitido".format([i]), self)
			return 
		
	if _passwordLineEdit.text.is_empty():
		Utils.ShowAlertDialog("Error", "La contraseña esta vacia.", self)
		return
		
	if _passwordLineEdit.text.length() < 3 || _usernameLineEdit.text.length() > 15:
		Utils.ShowAlertDialog("Error", "La contraseña tiene que tener un minimo de 3 caracteres y un maximo de 15 caracteres", self)
		return
		
	for i in _passwordLineEdit.text:
		if !Utils.LegalCharacter(i):
			Utils.ShowAlertDialog("Error", "Contraseña invalido: El caracter [{0}] no esta permitido".format([i]), self)
			return 
	 
	if _passwordLineEdit.text != _confirmPasswordLineEdit.text:
		Utils.ShowAlertDialog("Error", "Las contraseñas no coinciden", self)
		return
		
	if !Utils.IsEmailValid(_emailLineEdit.text):
		Utils.ShowAlertDialog("Error", "Email invalido", self)
		return
	
	Global.username = _usernameLineEdit.text
	
	GameProtocol.WriteLoginNewChar(_usernameLineEdit.text, \
		_passwordLineEdit.text, \
		_emailLineEdit.text, \
		_classOptionButton.selected + 1, \
		_raceOptionButton.selected + 1, \
		_genderOptionButton.selected + 1, \
		_homeOptionButton.selected + 1, \
		_GetHead(_raceOptionButton.selected + 1, _genderOptionButton.selected))
	_Flush()

func _Exit() -> void:
	ClientInterface.DisconnectFromHost()

func _ThrowDice() -> void:
	GameProtocol.WriteThrowDice()
	_Flush()

func _Flush() -> void:
	ClientInterface.Send(GameProtocol.Flush())

func _GetHead(race:int, gender:int) -> int:
	match gender:
		0: #Hombre
			match race:
				Enums.Race.Human:
					return randi_range(1, 40)
				Enums.Race.Elf:
					return randi_range(101, 122)
				Enums.Race.Drow:
					return randi_range(201, 221)
				Enums.Race.Dwarf:
					return randi_range(301, 319)
				Enums.Race.Gnome:
					return randi_range(401, 416)
					
		1: #Mujer
			match race:
				Enums.Race.Human:
					return randi_range(70, 89)
				Enums.Race.Elf:
					return randi_range(170, 188)
				Enums.Race.Drow:
					return randi_range(270, 288)
				Enums.Race.Dwarf:
					return randi_range(370, 384)
				Enums.Race.Gnome:
					return randi_range(470, 484)
					
	push_error("CLASE O RAZA INVALIDA")
	return 0
