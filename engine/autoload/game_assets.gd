extends Node

var _textureList:Dictionary[int, Texture2D]

var GrhDataList:Array[GrhData] = []
var ColoresPJ:Array[Color] = []
var FontDataList:Array[FontData] = []
var WeaponAnimationList:Array[GrhAnimationData] = []
var ShieldAnimationList:Array[GrhAnimationData] = []
var HeadAnimationList:Array[GrhAnimationData] = []
var HelmetAnimationList:Array[GrhAnimationData] = []
var BodyAnimationList:Array[GrhAnimationData] = []

func _ready() -> void:
	_LoadGrhData()
	_LoadWeaponData()
	_LoadShieldData()
	_LoadBodiesData()
	_LoadHeadData()
	_LoadHelmetData()
	_LoadFonts()
	_LoadColours()
	
func GetTexture(fileId:int) -> Texture2D:
	if _textureList.has(fileId):
		return _textureList.get(fileId)
	
	var texture = load("res://Assets/Gfx/%d.png" % fileId)
	_textureList.set(fileId, texture)

	return texture
	
func GetNickColor(id:int) -> Color:
	return ColoresPJ[id]

func GetMap(fileId:int) -> MapData:
	var mapData = MapData.new()
	
	var stream = StreamPeerBuffer.new() 
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Maps/mapa%d.map" % fileId)
	
	# Header
	stream.seek(2 + 255 + 4 + 4 + 8)
	
	for y in 100:
		for x in 100:
			var index = x + y * 100
			var flags = stream.get_u8()
			
			mapData.layer1[index] = stream.get_16()
			
			if flags & 0x1:
				mapData.flags[index] |= Enums.TileState.Blocked
			if flags & 0x2:
				mapData.layer2[index] = stream.get_16()
			if flags & 0x4:
				mapData.layer3.push_back(MapData.Sprite.new(x, y, stream.get_16())) 
			if flags & 0x8:
				mapData.layer4.push_back(MapData.Sprite.new(x, y, stream.get_16()))
			if flags & 0x10:
				if  stream.get_16() in [1, 2, 4]:
					mapData.flags[index] |= Enums.TileState.Roof 
			
			if ((mapData.layer1[index] >= 1505 && mapData.layer1[index] <= 1520) || \
				(mapData.layer1[index] >= 5665 && mapData.layer1[index] <= 5680) || \
				(mapData.layer1[index] >= 13547 && mapData.layer1[index] <= 13562)) && mapData.layer2[index] == 0:
					mapData.flags[index] |= Enums.TileState.Water 
	return mapData;

func _LoadColours() -> void:
	var initReader = ConfigFile.new()
	initReader.load("res://Assets/Init/colores.dat")
	
	ColoresPJ.resize(51)
	ColoresPJ.fill(Color.WHITE)
	
	for i in range(0, 49):
		ColoresPJ[i] = Color.from_rgba8(initReader.get_value(str(i), "R", 0), \
										initReader.get_value(str(i), "G", 0), \
										initReader.get_value(str(i), "B", 0))
	#Crimi
	ColoresPJ[50] = Color.from_rgba8(initReader.get_value("Cr", "R", 0), \
									initReader.get_value("Cr", "G", 0), \
									initReader.get_value("Cr", "B", 0))
	#Ciuda							
	ColoresPJ[49] = Color.from_rgba8(initReader.get_value("Ci", "R", 0), \
									initReader.get_value("Ci", "G", 0), \
									initReader.get_value("Ci", "B", 0))
	#Atacable							
	ColoresPJ[48] = Color.from_rgba8(initReader.get_value("At", "R", 0), \
									initReader.get_value("At", "G", 0), \
									initReader.get_value("At", "B", 0))
	
func _LoadFonts() -> void:
	FontDataList.resize(21)
	
	FontDataList[Enums.FontTypeNames.FontType_Talk] = FontData.new(Color.WHITE)
	FontDataList[Enums.FontTypeNames.FontType_Fight] = FontData.new(Color.RED, true)
	FontDataList[Enums.FontTypeNames.FontType_Warning] = FontData.new(Color.from_rgba8(32, 51, 223), true, true)
	FontDataList[Enums.FontTypeNames.FontType_Info] = FontData.new(Color.from_rgba8(65, 190, 156))
	FontDataList[Enums.FontTypeNames.FontType_InfoBold] = FontData.new(Color.from_rgba8(65, 190, 156), true)
	FontDataList[Enums.FontTypeNames.FontType_Ejecucion] = FontData.new(Color.from_rgba8(130, 130, 130), true)
	FontDataList[Enums.FontTypeNames.FontType_Party] = FontData.new(Color.from_rgba8(255, 180, 250))
	FontDataList[Enums.FontTypeNames.FontType_Veneno] = FontData.new(Color.from_rgba8(0, 255, 0))
	FontDataList[Enums.FontTypeNames.FontType_Guild] = FontData.new(Color.WHITE, true)
	FontDataList[Enums.FontTypeNames.FontType_Server] = FontData.new(Color.from_rgba8(0, 185, 0))
	FontDataList[Enums.FontTypeNames.FontType_GuildMsg] = FontData.new(Color.from_rgba8(228, 199, 27))
	FontDataList[Enums.FontTypeNames.FontType_Consejo] = FontData.new(Color.from_rgba8(130, 130, 255), true)
	FontDataList[Enums.FontTypeNames.FontType_ConsejoCaos] = FontData.new(Color.from_rgba8(255, 60, 0), true)
	FontDataList[Enums.FontTypeNames.FontType_ConsejoVesA] = FontData.new(Color.from_rgba8(0, 200, 255), true)
	FontDataList[Enums.FontTypeNames.FontType_ConsejoCaosVesA] = FontData.new(Color.from_rgba8(255, 50, 0), true)
	FontDataList[Enums.FontTypeNames.FontType_Centinela] = FontData.new(Color.from_rgba8(0, 255, 0), true)
	FontDataList[Enums.FontTypeNames.FontType_GMMsg] = FontData.new(Color.WHITE, false, true)
	FontDataList[Enums.FontTypeNames.FontType_GM] = FontData.new(Color.from_rgba8(30, 255, 30), true)
	FontDataList[Enums.FontTypeNames.FontType_Citizen] = FontData.new(Color.from_rgba8(0, 0, 200), true)
	FontDataList[Enums.FontTypeNames.FontType_Conse] = FontData.new(Color.from_rgba8(30, 150, 30), true)
	FontDataList[Enums.FontTypeNames.FontType_Dios] = FontData.new(Color.from_rgba8(250, 250, 150), true)

func _LoadGrhData() -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Init/graficos.ind")
	
	#Get file version
	stream.get_32()
	
	#Get number of grh
	var count = stream.get_32()
	
	GrhDataList.resize(count + 1)
	GrhDataList.fill(GrhData.new())
	
	while stream.get_position() < stream.get_size():
		var grhId = stream.get_32()
		var frameCount = stream.get_16()
		
		var grh = GrhData.new()
		grh.frameCount = frameCount
		grh.frames.resize(frameCount + 1)
		
		if frameCount > 1:
			for i in range(1, frameCount + 1):
				grh.frames[i] = stream.get_32()
				
			grh.speed = stream.get_float()
		else:
			grh.fileId = stream.get_32()
			
			grh.region.position.x = stream.get_16()
			grh.region.position.y = stream.get_16()
			grh.region.size.x = stream.get_16()
			grh.region.size.y = stream.get_16()
			grh.frames[1] = grhId
		
		GrhDataList[grhId] = grh 
		
func _LoadWeaponData() -> void:
	var initReader = ConfigFile.new()
	initReader.load("res://Assets/Init/armas.dat")
	
	var count = initReader.get_value("INIT", "NumArmas")
	WeaponAnimationList.resize(count + 1)
	WeaponAnimationList.fill(GrhAnimationData.new())
	
	for i in range(1, count + 1):
		if !initReader.has_section("ARMA%d" % i) : 
			continue
		
		var animation = GrhAnimationData.new()
		animation.north = initReader.get_value("ARMA%d" % i, "Dir1")
		animation.east  = initReader.get_value("ARMA%d" % i, "Dir2")
		animation.south = initReader.get_value("ARMA%d" % i, "Dir3")
		animation.west  = initReader.get_value("ARMA%d" % i, "Dir4")
		WeaponAnimationList[i] = animation 

func _LoadShieldData() -> void:
	var initReader = ConfigFile.new()
	initReader.load("res://Assets/Init/escudos.dat")
	
	var count = initReader.get_value("INIT", "NumEscudos")
	ShieldAnimationList.resize(count + 1)
	ShieldAnimationList.fill(GrhAnimationData.new())
	
	for i in range(1, count + 1):
		if !initReader.has_section("ESC%d" % i) : 
			continue
		
		var animation = GrhAnimationData.new()
		animation.north = initReader.get_value("ESC%d" % i, "Dir1")
		animation.east  = initReader.get_value("ESC%d" % i, "Dir2")
		animation.south = initReader.get_value("ESC%d" % i, "Dir3")
		animation.west  = initReader.get_value("ESC%d" % i, "Dir4")
		ShieldAnimationList[i] = animation 

func _LoadBodiesData() -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Init/personajes.ind")
	
	#Get header
	stream.get_data(255)
	stream.get_32()
	stream.get_32()
	
	#Get count
	var count = stream.get_16()
	
	BodyAnimationList.resize(count + 1)
	BodyAnimationList.fill(GrhAnimationData.new())
	
	for i in range(1, count + 1):
		var animation = GrhAnimationData.new()
		animation.north = stream.get_16()
		animation.east = stream.get_16()
		animation.south = stream.get_16()
		animation.west = stream.get_16()
		
		animation.offsetX = stream.get_16()
		animation.offsetY = stream.get_16()
		
		BodyAnimationList[i] = animation

func _LoadHeadData() -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Init/cabezas.ind")
	
	#Get header
	stream.get_data(255)
	stream.get_32()
	stream.get_32()
	
	#Get count
	var count = stream.get_16()
	
	HeadAnimationList.resize(count + 1)
	HeadAnimationList.fill(GrhAnimationData.new())
	
	for i in range(1, count + 1):
		var animation = GrhAnimationData.new()
		animation.north = stream.get_16()
		animation.east = stream.get_16()
		animation.south = stream.get_16()
		animation.west = stream.get_16()
		
		HeadAnimationList[i] = animation
		 
func _LoadHelmetData() -> void:
	var stream = StreamPeerBuffer.new()
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Init/cascos.ind")
	
	#Get header
	stream.get_data(255)
	stream.get_32()
	stream.get_32()
	
	#Get count
	var count = stream.get_16()
	
	HelmetAnimationList.resize(count + 1)
	HelmetAnimationList.fill(GrhAnimationData.new())
	
	for i in range(1, count + 1):
		var animation = GrhAnimationData.new()
		animation.north = stream.get_16()
		animation.east = stream.get_16()
		animation.south = stream.get_16()
		animation.west = stream.get_16()
		
		HelmetAnimationList[i] = animation
