extends Node

# VERSIÓN DEL BÁCULO: 10
const MAGIC_VERSION = 10

var _textureList = {}
var _itemIconList = {}
# Caché de GetMapInf: el .inf es estático y se lee repetido (Exportador + mapa del mundo).
var _map_inf_cache: Dictionary = {}
# Caché de texturas de GRH single-frame (para proyectiles/objetos dibujados en runtime).
var _grh_texture_cache: Dictionary = {}
# Caché de SpriteFrames construidos en runtime desde GrhData (proyectiles).
var _grh_sprite_frames_cache: Dictionary = {}
# Caché del ángulo base de una textura GRH (apunta la flecha hacia el objetivo).
var _grh_pointing_angle_cache: Dictionary = {}


var GrhDataList = []
var ColoresPJ = []
var FontDataList = []
var WeaponAnimationList = []
var ShieldAnimationList = []
var HeadAnimationList = []
var HelmetAnimationList = []
var BodyAnimationList = []
var SpellDataList = []

func _ready() -> void:
	print_rich("[color=yellow][b]*****************************************[/b][/color]")
	print_rich("[color=yellow][b]SISTEMA DE ASSETS: El báculo se despierta[/b][/color]")
	print_rich("[color=yellow][b]*****************************************[/b][/color]")
	
	# Carga forzada inmediata de hechizos para asegurar que estén en memoria
	_LoadSpellData()
	
	# Esperar a que Main termine de cargar sus recursos para el resto
	if get_tree().get_root().has_node('Main'):
		var main = get_node('/root/Main')
		if main and main.has_signal('resources_loaded'):
			main.resources_loaded.connect(_on_resources_loaded, CONNECT_ONE_SHOT)
	else:
		# Si por alguna razón no existe Main, cargar los recursos de inmediato
		call_deferred("_load_all_resources")

func _on_resources_loaded() -> void:
	call_deferred("_load_all_resources")

func _load_all_resources() -> void:
	_LoadGrhData()
	_LoadWeaponData()
	_LoadShieldData()
	_LoadBodiesData()
	_LoadHeadData()
	_LoadHelmetData()
	_LoadFonts()
	_LoadColours()
	_LoadSpellData()
	print("GameAssets: Todos los recursos han sido cargados")
	
func GetTexture(fileId:int) -> Texture2D:
	if _textureList.has(fileId):
		return _textureList.get(fileId)
	
	var texture = load("res://Assets/Gfx/%d.png" % fileId)
	_textureList.set(fileId, texture)

	return texture
	
func GetItemIcon(grhId: int) -> Texture2D:
	if grhId <= 0:
		return null
		
	if _itemIconList.has(grhId):
		return _itemIconList.get(grhId)
		
	if grhId >= GrhDataList.size() or GrhDataList[grhId] == null:
		return null
		
	var grh = GrhDataList[grhId]
	var frame_grh_id = grh.frames[1] if grh.frameCount > 1 else grhId
	if frame_grh_id >= GrhDataList.size() or GrhDataList[frame_grh_id] == null:
		return null
		
	var frame_grh = GrhDataList[frame_grh_id]
	var base_texture = GetTexture(frame_grh.fileId)
	if not base_texture:
		return null
		
	var rect = frame_grh.region
	var final_texture: Texture2D = null
	
	var img = base_texture.get_image()
	if img:
		var item_img = img
		if rect.size != Vector2.ZERO:
			item_img = img.get_region(Rect2i(rect))
		
		var used_rect = item_img.get_used_rect()
		if used_rect.size != Vector2i.ZERO:
			# Crear una sub-región de la textura base, recortando la transparencia
			var final_rect = Rect2(rect.position + Vector2(used_rect.position), Vector2(used_rect.size))
			var atlas = AtlasTexture.new()
			atlas.atlas = base_texture
			atlas.region = final_rect
			final_texture = atlas
			
	if not final_texture:
		var atlas = AtlasTexture.new()
		atlas.atlas = base_texture
		atlas.region = rect
		final_texture = atlas
		
	_itemIconList[grhId] = final_texture
	return final_texture

# Devuelve la textura (AtlasTexture) del PRIMER frame de un GrhData dado.
# A diferencia de GetItemIcon no recorta transparencia: devuelve la región completa
# (necesario para rotar flechas/proyectiles con pivote correcto).
func GetGrhTexture(grhId:int) -> Texture2D:
	if grhId <= 0:
		return null
	if _grh_texture_cache.has(grhId):
		return _grh_texture_cache.get(grhId)
	if grhId >= GrhDataList.size() or GrhDataList[grhId] == null:
		return null
		
	var grh = GrhDataList[grhId]
	var frame_grh_id = grh.frames[1] if grh.frameCount > 1 else grhId
	if frame_grh_id >= GrhDataList.size() or GrhDataList[frame_grh_id] == null:
		return null
		
	var frame_grh = GrhDataList[frame_grh_id]
	var base_texture = GetTexture(frame_grh.fileId)
	if not base_texture:
		return null
		
	var atlas = AtlasTexture.new()
	atlas.atlas = base_texture
	atlas.region = frame_grh.region
	_grh_texture_cache[grhId] = atlas
	return atlas

# Construye un SpriteFrames en runtime desde un GrhData (animación o frame único).
# La velocidad de animación se deriva del campo speed del GRH (duración total en ms),
# igual que el motor VB6: FrameDuration = Speed / NumFrames.
func BuildSpriteFramesFromGrh(grhId:int) -> SpriteFrames:
	if grhId <= 0:
		return null
	if _grh_sprite_frames_cache.has(grhId):
		return _grh_sprite_frames_cache.get(grhId)
	if grhId >= GrhDataList.size() or GrhDataList[grhId] == null:
		return null
		
	var grh = GrhDataList[grhId]
	var sprite_frames = SpriteFrames.new()
	
	if grh.frameCount > 1:
		for i in range(1, grh.frameCount + 1):
			var frame_grh_id = grh.frames[i]
			if frame_grh_id >= GrhDataList.size() or GrhDataList[frame_grh_id] == null:
				continue
			var frame_grh = GrhDataList[frame_grh_id]
			var base_texture = GetTexture(frame_grh.fileId)
			if not base_texture:
				continue
			var atlas = AtlasTexture.new()
			atlas.atlas = base_texture
			atlas.region = frame_grh.region
			sprite_frames.add_frame("default", atlas)
		# FPS derivado de la duración total (ms) igual que VB6
		if grh.speed > 0.0 and sprite_frames.get_frame_count("default") > 0:
			var fps = 1000.0 * float(sprite_frames.get_frame_count("default")) / grh.speed
			sprite_frames.set_animation_speed("default", clampf(fps, 1.0, 60.0))
	else:
		var texture = GetGrhTexture(grhId)
		if not texture:
			return null
		sprite_frames.add_frame("default", texture)
		
	if sprite_frames.get_frame_count("default") == 0:
		return null
		
	_grh_sprite_frames_cache[grhId] = sprite_frames
	return sprite_frames

# Calcula el ángulo (en radianes) hacia donde "apunta" la textura de un GRH:
# desde el centro de masa de píxeles visibles hacia el píxel más lejano (la punta).
# Se usa para orientar la flecha en vuelo hacia su trayectoria.
func GetGrhPointingAngle(grhId:int) -> float:
	if grhId <= 0:
		return 0.0
	if _grh_pointing_angle_cache.has(grhId):
		return _grh_pointing_angle_cache.get(grhId)
		
	var texture = GetGrhTexture(grhId)
	var angle = 0.0
	if texture:
		var img = texture.get_image()
		if img:
			var w = img.get_width()
			var h = img.get_height()
			var centroid := Vector2.ZERO
			var count := 0
			for x in w:
				for y in h:
					if img.get_pixel(x, y).a > 0.2:
						centroid += Vector2(x, y)
						count += 1
			if count > 0:
				centroid /= float(count)
				# Píxel visible más lejano del centro de masa = la punta
				var tip := centroid
				var max_dist_sq := 0.0
				for x in w:
					for y in h:
						if img.get_pixel(x, y).a > 0.2:
							var dist_sq = Vector2(x, y).distance_squared_to(centroid)
							if dist_sq > max_dist_sq:
								max_dist_sq = dist_sq
								tip = Vector2(x, y)
				angle = (tip - centroid).angle()
				
	_grh_pointing_angle_cache[grhId] = angle
	return angle

func GetNickColor(id:int) -> Color:
	return ColoresPJ[id]

func GetSpellName(spell_id_in) -> String:
	var spell_id = int(spell_id_in)
	
	print(">>> [V%d] GetSpellName(%d) - Memoria size: %d" % [MAGIC_VERSION, spell_id, SpellDataList.size()])
	
	if SpellDataList.is_empty():
		print("!!! [V%d] Memoria vacía, iniciando carga de emergencia..." % MAGIC_VERSION)
		_LoadSpellData()
	
	if spell_id == 0:
		return "(None)"
		
	if spell_id > 0 and spell_id < SpellDataList.size():
		var spell = SpellDataList[spell_id]
		if spell:
			return spell.nombre
	
	return "Hechizo " + str(spell_id)

func GetMap(fileId:int) -> MapData:
	var mapData = MapData.new()
	
	var stream = StreamPeerBuffer.new() 
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Maps/mapa%d.map" % fileId)
	
	# Header: MapVersion(2) + Desc(255) + CRC(4) + MagicWord(4) + Padding(8) = 273 bytes
	stream.seek(2 + 255 + 4 + 4 + 8)
	
	for y in 100:
		for x in 100:
			var index = x + y * 100
			var flags = stream.get_u8()
			
			# Layer 1 - GrhIndex es Long (4 bytes) en VB6
			mapData.layer1[index] = stream.get_32() # Ground layer
			
			if flags & 0x1:
				mapData.flags[index] |= Enums.TileState.Blocked
			if flags & 0x2:
				# Layer 2 - Long (4 bytes)
				mapData.layer2[index] = stream.get_32() # Decoration layer
			if flags & 0x4:
				# Layer 3 - Long (4 bytes)
				mapData.layer3.push_back(MapData.Sprite.new(x, y, stream.get_32())) # Vertical objects layer
			if flags & 0x8:
				# Layer 4 - Long (4 bytes)
				mapData.layer4.push_back(MapData.Sprite.new(x, y, stream.get_32())) # Roof layer (can be hidden)
			if flags & 0x10:
				# Trigger - Integer (2 bytes)
				# 1=BAJOTECHO (hide roof), 2=CASA (hide roof)
				var trigger = stream.get_16()
				# mapData.flags[index] = trigger
				if trigger in [1, 2]:
					mapData.flags[index] |= Enums.TileState.Roof
			# if flags & 0x20:
			# 	# Particle - Integer (2 bytes)
			# 	stream.get_16()
			
			# Detectar agua basándose en el GrhIndex de layer1
			if ((mapData.layer1[index] >= 1505 && mapData.layer1[index] <= 1520) || \
				(mapData.layer1[index] >= 5665 && mapData.layer1[index] <= 5680) || \
				(mapData.layer1[index] >= 13547 && mapData.layer1[index] <= 13562)) && mapData.layer2[index] == 0:
					mapData.flags[index] |= Enums.TileState.Water 
	return mapData

# Lee el archivo .inf del servidor VB6 y devuelve la lista de TileExit (teleports)
# definidos en el mapa. Cada entry es {x, y, dest_map, dest_x, dest_y} con
# coordenadas 1-100 (igual convención que el servidor).
# Retorna [] si el mapa no tiene .inf (p.ej. interiores sin cruces).
# Formato .inf (VB6 clsByteBuffer):
#   Header: 8 bytes (Double) + 2 bytes (Integer)
#   Por tile (Y outer, X inner, 1..100):
#     1 byte flags
#     if flags & 0x1: 3 × Integer (int16) -> TileExit.Map/X/Y
#     if flags & 0x2: 1 × Integer        -> NpcIndex
#     if flags & 0x4: 2 × Integer        -> ObjIndex, Amount
func GetMapInf(fileId: int) -> Array:
	if _map_inf_cache.has(fileId):
		return _map_inf_cache[fileId]
	var path := "res://Assets/Maps/Mapa%d.Inf" % fileId
	if not FileAccess.file_exists(path):
		# Los .Inf del servidor traen la extensión en mayúsculas o minúsculas
		# según el mapa (122 .Inf vs 195 .inf); en plataformas case-sensitive
		# hay que probar ambas o esos mapas pierden todos sus teleports.
		path = "res://Assets/Maps/Mapa%d.inf" % fileId
	if not FileAccess.file_exists(path):
		_map_inf_cache[fileId] = []
		return []
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.size() < 10:
		_map_inf_cache[fileId] = []
		return []
	var stream := StreamPeerBuffer.new()
	stream.data_array = bytes
	stream.seek(8 + 2) # header
	var exits: Array = []
	for y in range(1, 101):
		for x in range(1, 101):
			if stream.get_position() >= bytes.size():
				_map_inf_cache[fileId] = exits
				return exits
			var flags := stream.get_u8()
			if flags & 0x1:
				var dest_map := stream.get_16()
				var dest_x := stream.get_16()
				var dest_y := stream.get_16()
				if dest_map > 0:
					exits.append({
						"x": x, "y": y,
						"dest_map": int(dest_map),
						"dest_x": int(dest_x),
						"dest_y": int(dest_y),
					})
			if flags & 0x2:
				stream.get_16() # NpcIndex
			if flags & 0x4:
				stream.get_16() # ObjIndex
				stream.get_16() # Amount
	_map_inf_cache[fileId] = exits
	return exits

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
	
	print("GameAssets: Cargando %d gráficos desde graficos.ind" % count)
	
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
	# Eliminado fill para evitar instancias compartidas. Los índices vacíos serán null.
	
	# Obtener todas las secciones una sola vez para buscar
	var sections = initReader.get_sections()
	
	for i in range(1, count + 1):
		var section_name = _find_section_case_insensitive(sections, "ARMA%d" % i)
		if section_name.is_empty():
			continue
		
		var animation = GrhAnimationData.new()
		animation.north = initReader.get_value(section_name, "Dir1")
		animation.east  = initReader.get_value(section_name, "Dir2")
		animation.south = initReader.get_value(section_name, "Dir3")
		animation.west  = initReader.get_value(section_name, "Dir4")
		WeaponAnimationList[i] = animation 

func _LoadShieldData() -> void:
	var initReader = ConfigFile.new()
	initReader.load("res://Assets/Init/escudos.dat")
	
	var count = initReader.get_value("INIT", "NumEscudos")
	ShieldAnimationList.resize(count + 1)
	
	var sections = initReader.get_sections()
	
	for i in range(1, count + 1):
		var section_name = _find_section_case_insensitive(sections, "ESC%d" % i)
		if section_name.is_empty():
			continue
		
		var animation = GrhAnimationData.new()
		animation.north = initReader.get_value(section_name, "Dir1")
		animation.east  = initReader.get_value(section_name, "Dir2")
		animation.south = initReader.get_value(section_name, "Dir3")
		animation.west  = initReader.get_value(section_name, "Dir4")
		ShieldAnimationList[i] = animation 

func _LoadBodiesData() -> void:
	# Leer desde archivo binario Personajes.ind (formato VB6)
	# Estructura: Cabecera(263 bytes) + NumCuerpos(2 bytes) + N * tIndiceCuerpo(20 bytes)
	# tIndiceCuerpo: Body(1-4) as Long (4x4=16 bytes) + HeadOffsetX(2) + HeadOffsetY(2) = 20 bytes
	var stream = StreamPeerBuffer.new()
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Init/personajes.ind")
	
	# Saltar cabecera: Desc(255) + CRC(4) + MagicWord(4) = 263 bytes
	stream.seek(263)
	
	# Leer número de cuerpos (Integer = 2 bytes en VB6)
	var count = stream.get_16()
	print("GameAssets: Cargando %d cuerpos desde personajes.ind" % count)
	
	BodyAnimationList.resize(count + 1)
	
	for i in range(1, count + 1):
		var animation = GrhAnimationData.new()
		# Body(1) = North, Body(2) = East, Body(3) = South, Body(4) = West
		animation.north = stream.get_32()  # Body(1) - Long
		animation.east = stream.get_32()   # Body(2) - Long
		animation.south = stream.get_32()  # Body(3) - Long
		animation.west = stream.get_32()   # Body(4) - Long
		animation.offsetX = stream.get_16() # HeadOffsetX - Integer (signed)
		animation.offsetY = stream.get_16() # HeadOffsetY - Integer (signed)
		
		BodyAnimationList[i] = animation

func _LoadHeadData() -> void:
	# Leer desde archivo binario Cabezas.ind (formato VB6)
	# Estructura: Cabecera(263 bytes) + NumHeads(2 bytes) + N * tIndiceCabeza(16 bytes)
	# tIndiceCabeza: Head(1-4) as Long (4x4=16 bytes)
	var stream = StreamPeerBuffer.new()
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Init/cabezas.ind")
	
	# Saltar cabecera: Desc(255) + CRC(4) + MagicWord(4) = 263 bytes
	stream.seek(263)
	
	# Leer número de cabezas (Integer = 2 bytes en VB6)
	var count = stream.get_16()
	print("GameAssets: Cargando %d cabezas desde cabezas.ind" % count)
	
	HeadAnimationList.resize(count + 1)
	
	for i in range(1, count + 1):
		var animation = GrhAnimationData.new()
		# Head(1) = North, Head(2) = East, Head(3) = South, Head(4) = West
		animation.north = stream.get_32()  # Head(1) - Long
		animation.east = stream.get_32()   # Head(2) - Long
		animation.south = stream.get_32()  # Head(3) - Long
		animation.west = stream.get_32()   # Head(4) - Long
		
		HeadAnimationList[i] = animation

func _LoadHelmetData() -> void:
	# Leer desde archivo binario Cascos.ind (formato VB6)
	# Estructura: Cabecera(263 bytes) + NumCascos(2 bytes) + N * tIndiceCabeza(16 bytes)
	# tIndiceCabeza: Head(1-4) as Long (4x4=16 bytes)
	var stream = StreamPeerBuffer.new()
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Init/cascos.ind")
	
	# Saltar cabecera: Desc(255) + CRC(4) + MagicWord(4) = 263 bytes
	stream.seek(263)
	
	# Leer número de cascos (Integer = 2 bytes en VB6)
	var count = stream.get_16()
	print("GameAssets: Cargando %d cascos desde cascos.ind" % count)
	
	HelmetAnimationList.resize(count + 1)
	
	for i in range(1, count + 1):
		var animation = GrhAnimationData.new()
		# Head(1) = North, Head(2) = East, Head(3) = South, Head(4) = West
		animation.north = stream.get_32()  # Head(1) - Long
		animation.east = stream.get_32()   # Head(2) - Long
		animation.south = stream.get_32()  # Head(3) - Long
		animation.west = stream.get_32()   # Head(4) - Long
		
		HelmetAnimationList[i] = animation

func _find_section_case_insensitive(sections: PackedStringArray, target: String) -> String:
	# Búsqueda optimizada: Primero intentamos coincidencia exacta
	if sections.has(target):
		return target
		
	# Si falla, buscamos case-insensitive
	var target_lower = target.to_lower()
	for s in sections:
		if s.to_lower() == target_lower:
			return s
	return ""

func _LoadSpellData() -> void:
	print("--- [V%d] INICIO CARGA HECHIZOS ---" % MAGIC_VERSION)
	var path = "res://Assets/Init/Hechizos.dat"
	
	if !FileAccess.file_exists(path):
		print("!!! [V%d] ERROR: No existe %s" % [MAGIC_VERSION, path])
		return

	var initReader = ConfigFile.new()
	var err = initReader.load(path)
	if err != OK:
		print("!!! [V%d] ERROR ConfigFile: %d. Intentando lectura manual..." % [MAGIC_VERSION, err])
		_LoadSpellDataManual(path)
		return
		
	var count = initReader.get_value("INIT", "NUMHECHIZOS", 0)
	print("--- [V%d] Hechizos en archivo: %d" % [MAGIC_VERSION, count])
	
	SpellDataList.clear()
	SpellDataList.resize(count + 1)
	
	var SpellScript = load("res://common/data/spell_data.gd")
	for i in range(1, count + 1):
		var section = "HECHIZO%d" % i
		if initReader.has_section(section):
			var spell = SpellScript.new()
			spell.id = i
			spell.nombre = initReader.get_value(section, "Nombre", "Hechizo " + str(i))
			SpellDataList[i] = spell
	
	print("--- [V%d] CARGA COMPLETA: %d en memoria" % [MAGIC_VERSION, SpellDataList.size() - 1])

func _LoadSpellDataManual(path: String) -> void:
	print("--- [V%d] Iniciando lectura manual (fallback de emergencia) ---" % MAGIC_VERSION)
	var file = FileAccess.open(path, FileAccess.READ)
	if !file:
		print("!!! [V%d] ERROR: No se pudo abrir el archivo para lectura manual" % MAGIC_VERSION)
		return
	
	var SpellScript = load("res://common/data/spell_data.gd")
	var current_spell = null
	
	SpellDataList.clear()
	# Pre-llenamos con nulls para seguridad (AO suele tener ~500 hechizos max)
	SpellDataList.resize(1000)
	
	var loaded_count = 0
	while !file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("'") or line.begins_with(";"):
			continue
			
		if line.begins_with("[HECHIZO") and line.ends_with("]"):
			var id_str = line.replace("[HECHIZO", "").replace("]", "")
			if id_str.is_valid_int():
				var id = int(id_str)
				current_spell = SpellScript.new()
				current_spell.id = id
				if id < SpellDataList.size():
					SpellDataList[id] = current_spell
					loaded_count += 1
		elif "=" in line and current_spell:
			var parts = line.split("=", true, 1)
			var key = parts[0].strip_edges().to_upper()
			var val = parts[1].strip_edges()
			
			match key:
				"NOMBRE":
					current_spell.nombre = val
				"DESC":
					current_spell.desc = val
				"PALABRASMAGICAS":
					current_spell.palabras_magicas = val
	
	# Ajustar tamaño al final
	print("--- [V%d] Lectura manual finalizada. Hechizos cargados: %d ---" % [MAGIC_VERSION, loaded_count])
