extends Node
## Pantalla de Creación de Personajes - Estilo MMORPG
## Forja tu destino en las tierras de Argentum

# Referencias de UI - Datos del personaje
@export var _characterNameEdit: LineEdit

# Selectores de características
@export var _classOptionButton: OptionButton
@export var _raceOptionButton: OptionButton
@export var _genderOptionButton: OptionButton
@export var _homeOptionButton: OptionButton

# Preview del personaje
@export var _previewCharacter: Node2D

# Selector de cabezas
@export var _headIndexLabel: Label

# Atributos
@export var _attributeLabels: Array[Label]

# Info de clase
@export var _classDescriptionLabel: Label
@export var _classSpecialtyLabel: Label

# Animación
@export var _animationTimer: Timer

# Estado del personaje en creación
var _currentHead: int = 1
var _currentBody: int = 1
var _currentDirection: int = Enums.Heading.South
var _currentGender: int = 0  # 0 = Hombre, 1 = Mujer
var _currentRace: int = 1
var _currentClass: int = 1

# Atributos del personaje
var _attributes: Array[int] = [18, 18, 18, 18, 18]
const ATTRIBUTE_NAMES = ["Fuerza", "Agilidad", "Inteligencia", "Carisma", "Constitución"]

# Rangos de cabezas por raza y género
const HEAD_RANGES = {
	# Hombres
	"human_male": {"min": 1, "max": 40},
	"elf_male": {"min": 101, "max": 122},
	"drow_male": {"min": 201, "max": 221},
	"dwarf_male": {"min": 301, "max": 319},
	"gnome_male": {"min": 401, "max": 416},
	# Mujeres
	"human_female": {"min": 70, "max": 89},
	"elf_female": {"min": 170, "max": 188},
	"drow_female": {"min": 270, "max": 288},
	"dwarf_female": {"min": 370, "max": 384},
	"gnome_female": {"min": 470, "max": 484},
}

# Cuerpos desnudos por raza y género
const BODY_IDS = {
	"human_male": 1,
	"elf_male": 1,
	"drow_male": 1,
	"dwarf_male": 53,
	"gnome_male": 54,
	"human_female": 2,
	"elf_female": 2,
	"drow_female": 2,
	"dwarf_female": 55,
	"gnome_female": 56,
}

# Descripciones de clases
const CLASS_DESCRIPTIONS = {
	Enums.Class.Mage: "Maestro de las artes arcanas, capaz de desatar poderosos hechizos que devastan a sus enemigos.",
	Enums.Class.Cleric: "Sirviente de los dioses, canaliza el poder divino para sanar a sus aliados y castigar a los impíos.",
	Enums.Class.Warrior: "Experto en el combate cuerpo a cuerpo, su fuerza y resistencia son legendarias en todo el reino.",
	Enums.Class.Assassin: "Mortífero artista de las sombras, elimina a sus víctimas antes de que sepan que están en peligro.",
	Enums.Class.Thief: "Hábil ladronzuelo que sobrevive mediante el sigilo y la astucia, maestro del robo.",
	Enums.Class.Bard: "Músico errante cuyas melodías pueden inspirar valor o infundir terror en el corazón de los hombres.",
	Enums.Class.Druid: "Guardián de la naturaleza, comanda a las bestias salvajes y domina los elementos.",
	Enums.Class.Bandit: "Rudo combatiente sin honor que lucha sucio y golpea donde más duele.",
	Enums.Class.Paladin: "Santo guerrero al servicio del bien, combina fe inquebrantable con habilidad marcial.",
	Enums.Class.Hunter: "Rastreador experto que acecha a su presa con paciencia infinita y puntería mortal.",
	Enums.Class.Worker: "Artesano y recolector, maestro de las artes del oficio. Minería, pesca, tala y carpintería.",
	Enums.Class.Pirat: "Lobo de mar que domina las aguas, temido en todos los puertos del reino.",
}

const CLASS_SPECIALTIES = {
	Enums.Class.Mage: "Hechicería avanzada",
	Enums.Class.Cleric: "Sanación divina",
	Enums.Class.Warrior: "Combate con armas",
	Enums.Class.Assassin: "Apuñalar",
	Enums.Class.Thief: "Robar y Ocultarse",
	Enums.Class.Bard: "Música mágica",
	Enums.Class.Druid: "Domar animales",
	Enums.Class.Bandit: "Combate cuerpo a cuerpo",
	Enums.Class.Paladin: "Fe y espada",
	Enums.Class.Hunter: "Ocultarse y proyectiles",
	Enums.Class.Worker: "Minería, Pesca, Carpintería, Tala",
	Enums.Class.Pirat: "Navegación",
}

# Modificadores de raza
const RACE_MODIFIERS = {
	Enums.Race.Human: {"str": 0, "agi": 0, "int": 0, "cha": 0, "con": 0},
	Enums.Race.Elf: {"str": -1, "agi": 2, "int": 2, "cha": 1, "con": -1},
	Enums.Race.Drow: {"str": 0, "agi": 2, "int": 2, "cha": -1, "con": 0},
	Enums.Race.Gnome: {"str": -2, "agi": 2, "int": 3, "cha": 0, "con": -1},
	Enums.Race.Dwarf: {"str": 1, "agi": -1, "int": -1, "cha": -1, "con": 2},
}

func _ready() -> void:
	ClientInterface.disconnected.connect(_OnDisconnected)
	ClientInterface.dataReceived.connect(_OnDataReceived)
	
	_InitializeUI()
	_InitializeCharacterPreview()
	_ThrowDice()

func _exit_tree() -> void:
	if ClientInterface.disconnected.is_connected(_OnDisconnected):
		ClientInterface.disconnected.disconnect(_OnDisconnected)
	if ClientInterface.dataReceived.is_connected(_OnDataReceived):
		ClientInterface.dataReceived.disconnect(_OnDataReceived)

func _InitializeUI() -> void:
	# Cargar clases
	_classOptionButton.clear()
	for i in range(1, Consts.NumClases + 1):
		_classOptionButton.add_item(Consts.ClassNames[i])
	
	# Cargar razas
	_raceOptionButton.clear()
	for i in range(1, Consts.NumRazas + 1):
		_raceOptionButton.add_item(Consts.RaceNames[i])
	
	# Cargar géneros
	_genderOptionButton.clear()
	_genderOptionButton.add_item("Hombre")
	_genderOptionButton.add_item("Mujer")
	
	# Cargar hogares
	_homeOptionButton.clear()
	for i in range(1, Consts.NumCiudades):
		_homeOptionButton.add_item(Consts.HomeNames[i])
	
	# Conectar señales de los selectores
	_classOptionButton.item_selected.connect(_OnClassSelected)
	_raceOptionButton.item_selected.connect(_OnRaceSelected)
	_genderOptionButton.item_selected.connect(_OnGenderSelected)
	
	# Seleccionar valores iniciales
	_classOptionButton.select(0)
	_raceOptionButton.select(0)
	_genderOptionButton.select(0)
	_homeOptionButton.select(0)
	
	_OnClassSelected(0)
	_OnRaceSelected(0)
	_OnGenderSelected(0)

func _InitializeCharacterPreview() -> void:
	_UpdateBodyAndHead()
	_UpdatePreviewDirection()
	
	# Iniciar animación idle
	if _animationTimer:
		_animationTimer.timeout.connect(_OnAnimationTick)
		_animationTimer.start()

func _UpdateBodyAndHead() -> void:
	var race_key = _GetRaceKey()
	var head_range = HEAD_RANGES.get(race_key, {"min": 1, "max": 40})
	
	# Asegurar que la cabeza actual está en el rango válido
	_currentHead = clamp(_currentHead, head_range.min, head_range.max)
	if _currentHead < head_range.min or _currentHead > head_range.max:
		_currentHead = head_range.min
	
	# Obtener el cuerpo correcto
	_currentBody = BODY_IDS.get(race_key, 1)
	
	# Actualizar el preview sin efecto de refresh
	if _previewCharacter and _previewCharacter.has_node("Renderer"):
		var renderer = _previewCharacter.get_node("Renderer")
		if renderer:
			# Ocultar renderer antes del cambio
			renderer.modulate.a = 0.0
			
			# Cambiar los recursos
			renderer.body = _currentBody
			renderer.head = _currentHead
			renderer.heading = _currentDirection
			renderer.Stop()
			
			# Crear animación suave de fade-in
			var tween = create_tween()
			tween.tween_property(renderer, "modulate:a", 1.0, 0.1)
	
	_UpdateHeadLabel()

func _UpdateHeadLabel() -> void:
	if _headIndexLabel:
		var race_key = _GetRaceKey()
		var head_range = HEAD_RANGES.get(race_key, {"min": 1, "max": 40})
		var relative_index = _currentHead - head_range.min + 1
		var total_heads = head_range.max - head_range.min + 1
		_headIndexLabel.text = "%d / %d" % [relative_index, total_heads]

func _UpdatePreviewDirection() -> void:
	if _previewCharacter and _previewCharacter.has_node("Renderer"):
		var renderer = _previewCharacter.get_node("Renderer")
		if renderer:
			renderer.heading = _currentDirection
			renderer.Stop()

func _GetRaceKey() -> String:
	var race_names = ["human", "elf", "drow", "gnome", "dwarf"]
	var gender_suffix = "male" if _currentGender == 0 else "female"
	var race_name = race_names[_currentRace - 1] if _currentRace >= 1 and _currentRace <= 5 else "human"
	return "%s_%s" % [race_name, gender_suffix]

# === CALLBACKS DE UI ===

func _OnClassSelected(index: int) -> void:
	_currentClass = index + 1
	_UpdateClassInfo()

func _OnRaceSelected(index: int) -> void:
	_currentRace = index + 1
	_UpdateBodyAndHead()
	_UpdateAttributeDisplay()

func _OnGenderSelected(index: int) -> void:
	_currentGender = index
	_UpdateBodyAndHead()

func _UpdateClassInfo() -> void:
	if _classDescriptionLabel:
		_classDescriptionLabel.text = CLASS_DESCRIPTIONS.get(_currentClass, "")
	if _classSpecialtyLabel:
		_classSpecialtyLabel.text = "Especialidad: " + CLASS_SPECIALTIES.get(_currentClass, "")

func _OnHeadPrev() -> void:
	var race_key = _GetRaceKey()
	var head_range = HEAD_RANGES.get(race_key, {"min": 1, "max": 40})
	
	_currentHead -= 1
	if _currentHead < head_range.min:
		_currentHead = head_range.max
	
	_UpdateBodyAndHead()

func _OnHeadNext() -> void:
	var race_key = _GetRaceKey()
	var head_range = HEAD_RANGES.get(race_key, {"min": 1, "max": 40})
	
	_currentHead += 1
	if _currentHead > head_range.max:
		_currentHead = head_range.min
	
	_UpdateBodyAndHead()

func _OnDirectionLeft() -> void:
	match _currentDirection:
		Enums.Heading.North:
			_currentDirection = Enums.Heading.West
		Enums.Heading.West:
			_currentDirection = Enums.Heading.South
		Enums.Heading.South:
			_currentDirection = Enums.Heading.East
		Enums.Heading.East:
			_currentDirection = Enums.Heading.North
	_UpdatePreviewDirection()

func _OnDirectionRight() -> void:
	match _currentDirection:
		Enums.Heading.North:
			_currentDirection = Enums.Heading.East
		Enums.Heading.East:
			_currentDirection = Enums.Heading.South
		Enums.Heading.South:
			_currentDirection = Enums.Heading.West
		Enums.Heading.West:
			_currentDirection = Enums.Heading.North
	_UpdatePreviewDirection()

func _OnAnimationTick() -> void:
	# Hacer que el personaje se mueva ligeramente para dar vida
	if _previewCharacter and _previewCharacter.has_node("Renderer"):
		var renderer = _previewCharacter.get_node("Renderer")
		if renderer:
			renderer.Stop()

# === ATRIBUTOS ===

func _UpdateAttributeDisplay() -> void:
	var mods = RACE_MODIFIERS.get(_currentRace, {"str": 0, "agi": 0, "int": 0, "cha": 0, "con": 0})
	var mod_keys = ["str", "agi", "int", "cha", "con"]
	
	for i in range(min(_attributes.size(), _attributeLabels.size())):
		var base_val = _attributes[i]
		var mod_val = mods[mod_keys[i]]
		var final_val = base_val + mod_val
		
		var mod_text = ""
		if mod_val > 0:
			mod_text = " (+%d)" % mod_val
		elif mod_val < 0:
			mod_text = " (%d)" % mod_val
		
		if _attributeLabels[i]:
			_attributeLabels[i].text = "%s: %d%s" % [ATTRIBUTE_NAMES[i], final_val, mod_text]
			# Colorear el texto según el valor
			if final_val >= 20:
				_attributeLabels[i].modulate = Color(0.3, 1.0, 0.3)  # Verde
			elif final_val >= 16:
				_attributeLabels[i].modulate = Color(1.0, 0.9, 0.3)  # Amarillo/Dorado
			else:
				_attributeLabels[i].modulate = Color(1.0, 1.0, 1.0)  # Blanco normal

# === NETWORK ===

func _OnDisconnected() -> void:
	print("[CharacterCreation] Desconectado del servidor, volviendo a login...")
	Security.reset_redundance()
	var screen = load("uid://cd452cndcck7v").instantiate()
	ScreenController.SwitchScreen(screen)

func _OnDataReceived(data: PackedByteArray) -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = data
	
	while stream.get_position() < stream.get_size():
		var packetId = stream.get_u8()
		match packetId:
			Enums.ServerPacketID.DiceRoll:
				_HandleDiceRoll(stream.get_data(5)[1])
			Enums.ServerPacketID.ErrorMsg:
				Utils.ShowAlertDialog("Creación de Personaje", Utils.GetUnicodeString(stream), self)
			_:
				_HandleLogged(data)
				return

func _HandleLogged(data: PackedByteArray) -> void:
	var screen = load("uid://b2dyxo3826bub").instantiate() as GameScreen
	screen.networkMessages.append(data)
	
	ScreenController.SwitchScreen(screen)
	ClientInterface.dataReceived.disconnect(_OnDataReceived)

func _HandleDiceRoll(collection: Array[int]) -> void:
	for i in range(min(collection.size(), _attributes.size())):
		_attributes[i] = collection[i]
	_UpdateAttributeDisplay()

# === ACCIONES ===

func _OnRollDice() -> void:
	# Reproducir sonido de dados (cupdice.wav)
	AudioManager.PlayAudioByName("cupdice")
	_ThrowDice()

func _ThrowDice() -> void:
	GameProtocol.WriteThrowDice()
	_Flush()

func _Flush() -> void:
	ClientInterface.Send(GameProtocol.Flush())

func _OnCreateCharacter() -> void:
	# Validaciones
	var char_name = _characterNameEdit.text.strip_edges()
	
	if char_name.is_empty():
		Utils.ShowAlertDialog("¡Alto ahí, aventurero!", "Debes elegir un nombre para tu personaje.", self)
		return
	
	if char_name.length() < 3 or char_name.length() > 15:
		Utils.ShowAlertDialog("¡Nombre inválido!", "El nombre debe tener entre 3 y 15 caracteres.", self)
		return
	
	for c in char_name:
		if not Utils.LegalCharacter(c):
			Utils.ShowAlertDialog("¡Nombre prohibido!", "El carácter [%s] no está permitido en el nombre." % c, self)
			return
	
	# Verificar que los atributos estén tirados
	var sum_attrs = 0
	for attr in _attributes:
		sum_attrs += attr
	if sum_attrs == 0:
		Utils.ShowAlertDialog("¡Tira los dados!", "Debes tirar los dados para determinar tus atributos.", self)
		return
	
	# Todo OK, crear el personaje usando datos de la cuenta actual
	GameProtocol.WriteLoginNewChar(
		char_name,
		Global.account_hash,
		_classOptionButton.selected + 1,  # job/clase
		_raceOptionButton.selected + 1,   # raza
		_genderOptionButton.selected + 1, # género
		_homeOptionButton.selected + 1,   # hogar
		_currentHead                       # cabeza
	)
	_Flush()

func _OnBack() -> void:
	# Volver a la pantalla de selección de personajes con los datos guardados
	var char_selection = load("res://screens/character_selection_screen.tscn").instantiate()
	char_selection.set_account_data(Global.account_name, Global.account_characters)
	ScreenController.SwitchScreen(char_selection)

func _Exit() -> void:
	_OnBack()
