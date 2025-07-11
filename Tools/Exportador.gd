extends Node

@export var labelStatus: Label

func _ensure_directory_exists(path: String) -> void:
	var dir = DirAccess.open("res://")
	var path_parts = path.trim_prefix("res://").split("/")
	var current_path = "res://"
	
	for dir_name in path_parts:
		if dir_name.get_extension() != "":  # Es un archivo, no un directorio
			continue
			
		current_path = current_path.path_join(dir_name)
		if !DirAccess.dir_exists_absolute(current_path):
			dir.make_dir(current_path)
			await get_tree().process_frame # Dar tiempo a Godot para crear el directorio
	
func _CreateSprite(grhData:GrhData, x:int, y:int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = GameAssets.GetTexture(grhData.fileId)
	sprite.position = Vector2((x * 32) + 16, (y * 32) + 32);
	sprite.region_enabled = true
	sprite.region_rect = grhData.region
	sprite.offset = Vector2(0, -sprite.region_rect.size.y / 2);
	
	return sprite

func _AddTileSetAtlasSource(tiles:PackedInt32Array, tileSet:TileSet) -> void: 
	for tile in tiles:
		if tile == 0:
			continue
		
		if GameAssets.GrhDataList[tile].frameCount > 1:
			tile = GameAssets.GrhDataList[tile].frames[1]
		
		if GameAssets.GrhDataList[tile].fileId == 0:
			continue
			
		var grhData = GameAssets.GrhDataList[tile]
		if tileSet.has_source(grhData.fileId):
			continue
		
		var texture = GameAssets.GetTexture(grhData.fileId)
		var tileSetAtlasSource = TileSetAtlasSource.new()
		tileSetAtlasSource.texture_region_size = Vector2(32, 32)
		tileSetAtlasSource.texture = texture
		
		for y in texture.get_height() / 32:
			for x in texture.get_width() / 32:
				tileSetAtlasSource.create_tile(Vector2i(x, y))
				
		tileSet.add_source(tileSetAtlasSource, grhData.fileId)
	
func _AddTileMapLayer(tiles:PackedInt32Array, tileSet:TileSet) -> TileMapLayer:
	var tileMapLayer = TileMapLayer.new()
	tileMapLayer.tile_set = tileSet
	
	for y in 100:
		for x in 100:
			var tile = tiles[x + y * 100]
			
			if tile == 0:
				continue
				
			if GameAssets.GrhDataList[tile].frameCount > 1:
				tile = GameAssets.GrhDataList[tile].frames[1]
		
			var grhData = GameAssets.GrhDataList[tile]
			if !tileSet.has_source(grhData.fileId):
				continue
			tileMapLayer.set_cell(Vector2i(x, y), grhData.fileId, Vector2i(grhData.region.position) / 32)
	return tileMapLayer	
			
func _ExportAll() -> void:
	labelStatus.text = "Iniciando exportación..."
	await get_tree().process_frame
	
	await _Bodies()
	await _Heads()
	await _Weapons()
	await _Shields()
	await _ExportMaps()
	
	labelStatus.text = "¡Exportación completada con éxito!"
	await get_tree().create_timer(2.0).timeout
	labelStatus.text = "Listo"

func _ExportMaps() -> void:
	var files = Utils.GetFilesInDirectory("res://Assets/Maps/")
	var total = files.size()
	var current = 0
	
	for fileName in files:
		current += 1
		var mapNumber = fileName.substr(4)
		mapNumber = mapNumber.substr(0, mapNumber.find("."))
		
		labelStatus.text = "Exportando mapas... (%d/%d) Mapa %s" % [current, total, mapNumber]
		# Forzar actualización de la UI
		await get_tree().process_frame
		
		_ExportMap(int(mapNumber))
		
	labelStatus.text = "¡Exportación de mapas completada!"
					
func _ExportMap(fileId:int) -> void:
	var mapData = GameAssets.GetMap(fileId)
	var tileSet = TileSet.new()
	
	tileSet.tile_size = Vector2(32, 32) 
	
	_AddTileSetAtlasSource(mapData.layer1, tileSet)
	_AddTileSetAtlasSource(mapData.layer2, tileSet)
	
	var mainNode = Node2D.new()
	var packedScene = PackedScene.new()
	
	var layer1 = _AddTileMapLayer(mapData.layer1, tileSet)
	var layer2 = _AddTileMapLayer(mapData.layer2, tileSet)
	var layer3 = Node2D.new()
	
	mainNode.set_meta("data", mapData.flags)
	mainNode.name = "MapView"
	layer1.name = "Layer1"
	layer2.name = "Layer2" 
	layer3.name = "Layer3"
	layer3.y_sort_enabled = true
	
	mainNode.add_child(layer1)
	mainNode.add_child(layer2) 
	mainNode.add_child(layer3) 
	
	layer1.owner = mainNode
	layer2.owner = mainNode
	layer3.owner = mainNode
	
	for object in mapData.layer3:
		if GameAssets.GrhDataList[object.grhId].frameCount > 1:
			object.grhId = GameAssets.GrhDataList[object.grhId].frames[1]
			
		var grhData = GameAssets.GrhDataList[object.grhId]
		if grhData.fileId:
			var sprite = _CreateSprite(grhData, object.x, object.y)
			layer3.add_child(sprite)
			sprite.owner = mainNode
		
	if packedScene.pack(mainNode) == OK:
		var save_path = "res://Maps/Map%d.tscn" % fileId
		_ensure_directory_exists(save_path.get_base_dir())
		ResourceSaver.save(packedScene, save_path) 


func _AttachHeadAnimation(spriteFrames:SpriteFrames, name:String, grhId:int) -> void:
	var frame = GameAssets.GrhDataList[grhId]
	var atlasTexture = AtlasTexture.new()
	
	atlasTexture.region = frame.region
	atlasTexture.atlas = GameAssets.GetTexture(frame.fileId)

	spriteFrames.add_animation("idle_" + name);
	spriteFrames.add_frame("idle_" + name, atlasTexture);

func _AttachAnimation(spriteFrames:SpriteFrames, name:String, grhId:int) -> void:
	spriteFrames.add_animation("idle_" + name)
	spriteFrames.add_animation("walk_" + name)

	spriteFrames.set_animation_speed("idle_" + name, 1)
	spriteFrames.set_animation_speed("walk_" + name, 12.0)
	
	var frames = GameAssets.GrhDataList[grhId].frames
	for i in range(1, frames.size()):
		var frame = GameAssets.GrhDataList[frames[i]]
		
		if frame.fileId == 0:
			push_error("Frame {%d} has no file" % frames[i]) 
		
		var atlasTexture = AtlasTexture.new();
		atlasTexture.region = frame.region
		atlasTexture.atlas = GameAssets.GetTexture(frame.fileId)
		
		spriteFrames.add_frame("walk_" + name, atlasTexture)
		if i == 1:
			spriteFrames.add_frame("idle_" + name, atlasTexture)
	
	
func _Bodies() -> void:
	var total = GameAssets.BodyAnimationList.size() - 1
	labelStatus.text = "Exportando cuerpos... (0/%d)" % total
	
	for i in range(1, GameAssets.BodyAnimationList.size()):
		labelStatus.text = "Exportando cuerpos... (%d/%d)" % [i, total]
		# Forzar actualización de la UI
		await get_tree().process_frame
		var data = GameAssets.BodyAnimationList[i]
		var spriteFrames = SpriteFrames.new()
		
		spriteFrames.set_meta("offset_x", data.offsetX);
		spriteFrames.set_meta("offset_y", data.offsetY);
		
		spriteFrames.remove_animation("default")
		_AttachAnimation(spriteFrames, "west", data.west);
		_AttachAnimation(spriteFrames, "east", data.east);
		_AttachAnimation(spriteFrames, "south", data.south);
		_AttachAnimation(spriteFrames, "north", data.north);
		
		var save_path = "res://Resources/Character/Bodies/body_%d.tres" % i
		_ensure_directory_exists(save_path.get_base_dir())
		ResourceSaver.save(spriteFrames, save_path);	
	
func _Weapons() -> void:
	var total = GameAssets.WeaponAnimationList.size() - 1
	labelStatus.text = "Exportando armas... (0/%d)" % total
	
	for i in range(1, GameAssets.WeaponAnimationList.size()):
		if i % 10 == 0:  # Actualizar cada 10 armas para no saturar
			labelStatus.text = "Exportando armas... (%d/%d)" % [i, total]
			# Forzar actualización de la UI
			await get_tree().process_frame
		if i == Consts.NoAnim:
			continue
			
		var data = GameAssets.WeaponAnimationList[i]
		var spriteFrames = SpriteFrames.new()

		spriteFrames.remove_animation("default")
		_AttachAnimation(spriteFrames, "west", data.west);
		_AttachAnimation(spriteFrames, "east", data.east);
		_AttachAnimation(spriteFrames, "south", data.south);
		_AttachAnimation(spriteFrames, "north", data.north);
		
		var save_path = "res://Resources/Character/Weapons/weapon_%d.tres" % i
		_ensure_directory_exists(save_path.get_base_dir())
		ResourceSaver.save(spriteFrames, save_path);	

func _Shields() -> void:
	var total = GameAssets.ShieldAnimationList.size() - 1
	labelStatus.text = "Exportando escudos... (0/%d)" % total
	
	for i in range(1, GameAssets.ShieldAnimationList.size()):
		if i % 10 == 0:  # Actualizar cada 10 escudos para no saturar
			labelStatus.text = "Exportando escudos... (%d/%d)" % [i, total]
			# Forzar actualización de la UI
			await get_tree().process_frame
		if i == Consts.NoAnim:
			continue
			
		var data = GameAssets.ShieldAnimationList[i]
		var spriteFrames = SpriteFrames.new()

		spriteFrames.remove_animation("default")
		_AttachAnimation(spriteFrames, "west", data.west);
		_AttachAnimation(spriteFrames, "east", data.east);
		_AttachAnimation(spriteFrames, "south", data.south);
		_AttachAnimation(spriteFrames, "north", data.north);
		
		var save_path = "res://Resources/Character/Shields/shield_%d.tres" % i
		_ensure_directory_exists(save_path.get_base_dir())
		ResourceSaver.save(spriteFrames, save_path);	
		
func _Heads() -> void:
	var total = GameAssets.HeadAnimationList.size() - 1
	labelStatus.text = "Exportando cabezas... (0/%d)" % total
	
	for i in range(1, GameAssets.HeadAnimationList.size()):
		if i % 10 == 0:  # Actualizar cada 10 cabezas para no saturar
			labelStatus.text = "Exportando cabezas... (%d/%d)" % [i, total]
			# Forzar actualización de la UI
			await get_tree().process_frame
		var data = GameAssets.HeadAnimationList[i]
		var spriteFrames = SpriteFrames.new()
		
		if 0 in [data.east, data.north, data.south, data.west]:
			continue
			
		spriteFrames.remove_animation("default")
		_AttachHeadAnimation(spriteFrames, "west", data.west);
		_AttachHeadAnimation(spriteFrames, "east", data.east);
		_AttachHeadAnimation(spriteFrames, "south", data.south);
		_AttachHeadAnimation(spriteFrames, "north", data.north);
		
		var save_path = "res://Resources/Character/Heads/head_%d.tres" % i
		_ensure_directory_exists(save_path.get_base_dir())
		ResourceSaver.save(spriteFrames, save_path);	

func _Helmets() -> void:
	for i in range(1, GameAssets.HelmetAnimationList.size()):
		var data = GameAssets.HelmetAnimationList[i]
		var spriteFrames = SpriteFrames.new()
		
		if 0 in [data.east, data.north, data.south, data.west]:
			continue
			
		spriteFrames.remove_animation("default")
		_AttachHeadAnimation(spriteFrames, "west", data.west);
		_AttachHeadAnimation(spriteFrames, "east", data.east);
		_AttachHeadAnimation(spriteFrames, "south", data.south);
		_AttachHeadAnimation(spriteFrames, "north", data.north);
		
		ResourceSaver.save(spriteFrames, "res://Resources/Character/Helmets/helmet_%d.tres" % i);	


func _Fxs() -> void: 
	var stream = StreamPeerBuffer.new()
	stream.data_array = FileAccess.get_file_as_bytes("res://Assets/Init/fxs.ind")
	
	#Get header
	stream.get_data(255)
	stream.get_32()
	stream.get_32()
	
	var count = stream.get_16()
	for i in count:
		var grh_id = stream.get_16()
		var offset_x = stream.get_16()
		var offset_y = stream.get_16()
		
		var frames = GameAssets.GrhDataList[grh_id].frames 
		var spriteFrames = SpriteFrames.new()
		
		spriteFrames.set_animation_speed("default", 12.0)
		spriteFrames.set_animation_loop("default", false)
		
		spriteFrames.set_meta("offset_x", offset_x);
		spriteFrames.set_meta("offset_y", offset_y);
		
		for f in range(1, frames.size()):
			var grh_data = GameAssets.GrhDataList[frames[f]]
			var atlas_texture = AtlasTexture.new()
			atlas_texture.region = grh_data.region
			atlas_texture.atlas = GameAssets.GetTexture(grh_data.fileId)
			
			spriteFrames.add_frame("default", atlas_texture)
			
		ResourceSaver.save(spriteFrames, "res://Resources/Fxs/fx_%d.tres" % (i + 1))	

### PACKAGES

func _createPackageMaps() -> void:
	# Obtener lista de archivos de mapa
	var map_files = []
	var dir = DirAccess.open("res://Maps/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn") and file_name.begins_with("Map"):
				map_files.append(file_name)
			file_name = dir.get_next()
	else:
		push_error("No se pudo abrir el directorio de mapas")
		return

	# Obtener miniaturas de mapas
	var thumbnails_dir = DirAccess.open("res://Assets/minimap_thumbnails/")
	var thumbnail_files = []
	if thumbnails_dir:
		thumbnails_dir.list_dir_begin()
		var file_name = thumbnails_dir.get_next()
		while file_name != "":
			if not thumbnails_dir.current_is_dir():
				thumbnail_files.append(file_name)
			file_name = thumbnails_dir.get_next()

	var total = map_files.size() + thumbnail_files.size()
	if total == 0:
		labelStatus.text = "No se encontraron mapas ni miniaturas para exportar"
		return

	labelStatus.text = "Exportando mapas y miniaturas PCK... (0/%d)" % total
	await get_tree().process_frame

	# Crear el archivo PCK
	var packer = PCKPacker.new()
	var output_path = "res://maps.pck"
	
	if packer.pck_start(output_path) != OK:
		push_error("Error al crear el archivo PCK de mapas")
		labelStatus.text = "Error al crear el archivo PCK de mapas"
		return

	# Contador de archivos procesados
	var processed = 0

	# Agregar mapas al PCK
	for i in range(map_files.size()):
		var map_file = map_files[i]
		var map_path = "res://Maps/" + map_file
		var relative_path = "Maps/" + map_file  # Ruta relativa dentro del PCK
		
		processed += 1
		labelStatus.text = "Exportando mapas PCK... (%d/%d) %s" % [processed, total, map_file]
		await get_tree().process_frame
		
		# Usar _add_file_to_pack en lugar de packer.add_file directamente
		_add_file_to_pack(packer, map_path, relative_path)

	# Agregar miniaturas al PCK
	for i in range(thumbnail_files.size()):
		var thumb_file = thumbnail_files[i]
		var thumb_path = "res://Assets/minimap_thumbnails/" + thumb_file
		var relative_path = "Assets/minimap_thumbnails/" + thumb_file
		
		processed += 1
		labelStatus.text = "Exportando miniaturas PCK... (%d/%d) %s" % [processed, total, thumb_file]
		await get_tree().process_frame
		
		# Usar _add_file_to_pack en lugar de packer.add_file directamente
		_add_file_to_pack(packer, thumb_path, relative_path)
	
	# Finalizar y guardar el PCK
	if packer.flush() == OK:
		labelStatus.text = "PCK creado exitosamente: %s (%d archivos)" % [output_path, processed]
		print("Paquete de mapas creado con éxito con %d archivos" % processed)
	else:
		labelStatus.text = "Error al guardar el archivo PCK"
		push_error("Error al guardar el archivo PCK")

func _createPackageIndex() -> void:
	# Directorios a incluir en el paquete Index
	var asset_dirs = [
		{ "path": "res://Assets/Init/", "prefix": "Assets/Init/" },
		{ "path": "res://Assets/UI/", "prefix": "Assets/UI/" },
		{ "path": "res://Assets/Fonts/alegreya-sans/", "prefix": "Assets/Fonts/alegreya-sans/" },
		{ "path": "res://Assets/Cursors/", "prefix": "Assets/Cursors/" },
	]
	
	# Diccionario para almacenar archivos por directorio
	var all_files = {}
	var total_files = 0
	
	# Obtener lista de archivos de cada directorio
	for dir_info in asset_dirs:
		var dir_path = dir_info["path"]
		var files = []
		var dir = DirAccess.open(dir_path)
		
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					files.append(file_name)
					total_files += 1
				file_name = dir.get_next()
		else:
			push_warning("No se pudo abrir el directorio: " + dir_path)
		
		all_files[dir_path] = {
			"prefix": dir_info["prefix"],
			"files": files
		}
	
	if total_files == 0:
		labelStatus.text = "No se encontraron archivos para empaquetar"
		return

	labelStatus.text = "Preparando para empaquetar %d archivos..." % total_files
	await get_tree().process_frame

	# Crear el archivo PCK
	var packer = PCKPacker.new()
	var output_path = "res://index.pck"
	
	if packer.pck_start(output_path) != OK:
		push_error("Error al crear el archivo PCK de Index")
		labelStatus.text = "Error al crear el archivo PCK"
		return

	# Contador de archivos procesados
	var processed = 0
	
	# Agregar cada archivo al PCK
	for dir_path in all_files:
		var dir_info = all_files[dir_path]
		var file_prefix = dir_info["prefix"]
		var files = dir_info["files"]
		
		for file_name in files:
			var file_path = dir_path + file_name
			var relative_path = file_prefix + file_name  # Ruta relativa dentro del PCK
			
			processed += 1
			labelStatus.text = "Exportando UI... (%d/%d) %s" % [processed, total_files, file_name]
			await get_tree().process_frame
			
			# Usar _add_file_to_pack en lugar de packer.add_file directamente
			_add_file_to_pack(packer, file_path, relative_path)
	
	# Finalizar y guardar el PCK
	if packer.flush() == OK:
		labelStatus.text = "PCK de Index creado exitosamente: %s (%d archivos)" % [output_path, processed]
		print("Paquete Index creado con éxito con %d archivos" % processed)
	else:
		labelStatus.text = "Error al guardar el archivo PCK de Index"
		push_error("Error al guardar el archivo PCK de Index")

# Función para procesar archivos .import y obtener sus recursos asociados
func _process_import_file(import_path: String) -> Dictionary:
	var result = {
		"import_file": "",
		"remap_path": "",
		"dependencies": []
	}
	
	# Verificar si el archivo .import existe
	if not import_path.ends_with(".import"):
		return result
		
	if not FileAccess.file_exists(import_path):
		push_error("El archivo .import no existe: " + import_path)
		return result
		
	result["import_file"] = import_path
	
	# Leer el contenido del archivo .import
	var file = FileAccess.open(import_path, FileAccess.READ)
	if not file:
		push_error("No se pudo abrir el archivo: " + import_path)
		return result
		
	var content = file.get_as_text()
	file.close()
	
	# Buscar la sección [remap] y extraer el path
	var lines = content.split("\n")
	var in_remap_section = false
	
	for line in lines:
		line = line.strip_edges()
		
		# Buscar la sección [remap]
		if line == "[remap]":
			in_remap_section = true
			continue
		elif line.begins_with("[") and line.ends_with("]"):
			in_remap_section = false
			continue
			
		# Procesar la sección [remap]
		if in_remap_section and line.begins_with("path=\""):
			var path = line.trim_prefix("path=\"").split("\"")[0]
			if path.begins_with("res://") and FileAccess.file_exists(path):
				result["remap_path"] = path
				result["dependencies"].append(path)
				print("Ruta remapeada encontrada: ", path)
	
	# Buscar dependencias en la sección [deps]
	var in_deps_section = false
	var in_dest_files = false
	
	for line in lines:
		line = line.strip_edges()
		
		# Buscar la sección [deps]
		if line == "[deps]":
			in_deps_section = true
			continue
		elif line.begins_with("[") and line.ends_with("]"):
			in_deps_section = false
			in_dest_files = false
			continue
			
		# Buscar la sección dest_files dentro de [deps]
		if in_deps_section and line == "dest_files=[":
			in_dest_files = true
			continue
		elif in_dest_files and line == "]":
			in_dest_files = false
			continue
			
		# Procesar dest_files
		if in_dest_files and line.begins_with("\""):
			var dep_path = line.trim_prefix("\"").split("\"")[0]
			if dep_path.begins_with("res://") and FileAccess.file_exists(dep_path):
				if not dep_path in result["dependencies"]:
					result["dependencies"].append(dep_path)
					print("Dependencia encontrada en .import: ", dep_path)
	
	# Si no encontramos dependencias, intentar con el archivo .import.remap
	if result["dependencies"].size() == 0:
		var remap_path = import_path + ".remap"
		if FileAccess.file_exists(remap_path):
			var remap_file = FileAccess.open(remap_path, FileAccess.READ)
			if remap_file:
				var remap_content = remap_file.get_as_text()
				remap_file.close()
				
				# Buscar líneas que parezcan rutas de archivo
				var remap_lines = remap_content.split("\n")
				for remap_line in remap_lines:
					remap_line = remap_line.strip_edges()
					if remap_line.begins_with("res://.godot/imported/") and not remap_line.begins_with("res://.godot/imported/.godot"):
						if not remap_line in result["dependencies"] and FileAccess.file_exists(remap_line):
							result["dependencies"].append(remap_line)
							print("Dependencia encontrada en .remap: ", remap_line)
	
	print("Procesado ", import_path, " - ", result["dependencies"].size(), " dependencias encontradas")
	return result

# Función para agregar un archivo al PCK, incluyendo sus archivos .import y recursos asociados
func _add_file_to_pack(packer: PCKPacker, path: String, relative_path: String) -> void:
	# Verificar si el archivo principal existe
	if not FileAccess.file_exists(path):
		push_error("El archivo no existe: " + path)
		return
	
	# 1. Agregar el archivo principal
	if packer.add_file(relative_path, path) != OK:
		push_error("Error al agregar el archivo al paquete: " + path)
	else:
		print("Archivo empaquetado: " + relative_path)
	
	# 2. Verificar si existe un archivo .import correspondiente
	var import_path = path + ".import"
	if FileAccess.file_exists(import_path):
		# Agregar el archivo .import
		var import_relative_path = relative_path + ".import"
		
		# Procesar el archivo .import para encontrar recursos adicionales
		var import_info = _process_import_file(import_path)
		
		# 3. Agregar el archivo remapeado si existe
		if import_info["remap_path"] != "" and FileAccess.file_exists(import_info["remap_path"]):
			# Calcular la ruta relativa dentro del PCK para el archivo remapeado
			# Mantenemos la estructura de directorios dentro de .godot/imported/
			var remap_relative_path = import_info["remap_path"].replace("res://", "")
			
			if packer.add_file(remap_relative_path, import_info["remap_path"]) != OK:
				push_error("Error al agregar el archivo remapeado al paquete: " + import_info["remap_path"])
			else:
				print("Archivo remapeado empaquetado: " + remap_relative_path)
		
		# 4. Agregar todas las dependencias encontradas
		for dep_path in import_info["dependencies"]:
			if dep_path != import_info["remap_path"] and FileAccess.file_exists(dep_path):
				# Mantenemos la estructura de directorios original
				var dep_relative_path = dep_path.replace("res://", "")
				
				# Verificar si ya se agregó este archivo para evitar duplicados
				if not _is_file_in_pack(packer, dep_relative_path):
					if packer.add_file(dep_relative_path, dep_path) != OK:
						push_error("Error al agregar dependencia al paquete: " + dep_path)
					else:
						print("Dependencia empaquetada: " + dep_relative_path)

# Función auxiliar para verificar si un archivo ya está en el paquete
func _is_file_in_pack(_packer: PCKPacker, _relative_path: String) -> bool:
	# Esta es una función auxiliar que podría necesitar ser implementada de manera diferente
	# dependiendo de cómo se pueda verificar si un archivo ya está en el paquete
	# En Godot 4, no hay una forma directa de verificar esto, así que por ahora asumimos que no está
	return false

func _createPackageSound() -> void:
	print("Iniciando creación del paquete de sonidos...")

	# Directorios a incluir en el paquete de sonidos
	var asset_dirs = [
		{ "path": "res://Assets/Sfx/", "prefix": "Assets/Sfx/" },
		{ "path": "res://Assets/Music/", "prefix": "Assets/Music/" }
	]
	
	# Diccionario para almacenar archivos por directorio
	var all_files = {}
	var total_files = 0
	
	print("Buscando archivos de audio en los directorios...")
	
	# Obtener lista de archivos de cada directorio
	for dir_info in asset_dirs:
		var dir_path = dir_info["path"]
		var files = []
		var dir = DirAccess.open(dir_path)
		
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir():
					# Solo incluir archivos de audio y sus .import
					var ext = file_name.get_extension().to_lower()
					if ext in ["wav", "ogg", "mp3", "mp4"] or file_name.ends_with(".import"):
						files.append(file_name)
						total_files += 1
				file_name = dir.get_next()
			
			dir.list_dir_end()
			all_files[dir_path] = { "files": files, "prefix": dir_info["prefix"] }
			print("Encontrados ", files.size(), " archivos en ", dir_path)
		else:
			push_error("No se pudo abrir el directorio: " + dir_path)

	if total_files == 0:
		labelStatus.text = "No se encontraron archivos de audio para empaquetar"
		push_error("No se encontraron archivos de audio para empaquetar")
		return

	print("Buscando dependencias de importación...")
	
	# Crear una lista de archivos adicionales (dependencias de importación)
	var additional_files = {}
	
	# Procesar archivos .import para encontrar dependencias
	for dir_path in all_files:
		var files = all_files[dir_path]["files"]
		for file_name in files:
			if file_name.ends_with(".import"):
				var import_path = dir_path + file_name
				print("Procesando archivo .import: ", import_path)
				
				# Procesar el archivo .import para encontrar dependencias
				var deps = _process_import_file(import_path)
				
				# Asegurarse de que el archivo .import en sí se incluya
				var import_relative_path = all_files[dir_path]["prefix"] + file_name
				if not additional_files.has(import_path):
					additional_files[import_path] = import_relative_path
					total_files += 1
					print("Añadido archivo .import: ", import_path, " como ", import_relative_path)
				
				# Procesar las dependencias encontradas
				for dep in deps:
					if not additional_files.has(dep) and FileAccess.file_exists(dep):
						# Calcular la ruta relativa dentro del PCK
						var relative_path = dep.replace("res://", "")
						additional_files[dep] = relative_path
						total_files += 1
						print("Añadida dependencia: ", dep, " como ", relative_path)

	print("Total de archivos a empaquetar: ", total_files)

	labelStatus.text = "Preparando para empaquetar %d archivos de audio..." % total_files
	await get_tree().process_frame

	# Crear el archivo PCK
	var packer = PCKPacker.new()
	var output_path = "res://sounds.pck"
	
	print("Creando archivo PCK en: ", output_path)
	
	if packer.pck_start(output_path) != OK:
		push_error("Error al crear el archivo PCK de sonidos")
		labelStatus.text = "Error al crear el archivo PCK de sonidos"
		return

	# Contador de archivos procesados
	var processed = 0
	
	print("Agregando archivos de audio al paquete...")
	
	# Agregar archivos de audio y .import al PCK
	for dir_path in all_files:
		var dir_info = all_files[dir_path]
		var file_prefix = dir_info["prefix"]
		var files = dir_info["files"]
		
		for file_name in files:
			var file_path = dir_path + file_name
			var relative_path = file_prefix + file_name  # Ruta relativa dentro del PCK
			
			processed += 1
			var status = "Exportando sonidos... (%d/%d) %s" % [processed, total_files, file_name]
			labelStatus.text = status
			print(status)
			
			# Agregar el archivo al paquete
			_add_file_to_pack(packer, file_path, relative_path)
			
			# Dar tiempo para actualizar la interfaz
			if processed % 10 == 0:
				await get_tree().process_frame
	
	print("Agregando archivos de dependencias...")
	
	# Agregar archivos adicionales (dependencias de importación)
	for dep_path in additional_files:
		var relative_path = additional_files[dep_path]
		processed += 1
		var status = "Exportando dependencias... (%d/%d) %s" % [processed, total_files, relative_path]
		labelStatus.text = status
		print(status)
		
		# Agregar el archivo de dependencia al paquete
		if FileAccess.file_exists(dep_path):
			_add_file_to_pack(packer, dep_path, relative_path)
		else:
			push_error("El archivo de dependencia no existe: " + dep_path)
			print("Error: El archivo de dependencia no existe: ", dep_path)
		
		# Dar tiempo para actualizar la interfaz
		if processed % 10 == 0:
			await get_tree().process_frame

	print("Finalizando creación del paquete...")
	
	# Finalizar y guardar el PCK
	if packer.flush() == OK:
		var success_msg = "PCK de sonidos creado exitosamente: %s (%d archivos)" % [output_path, processed]
		labelStatus.text = success_msg
		print(success_msg)
		print("Paquete de sonidos creado con éxito con %d archivos" % processed)
	else:
		var error_msg = "Error al guardar el archivo PCK de sonidos"
		labelStatus.text = error_msg
		push_error(error_msg)
		print(error_msg)


func _createPackageGrh() -> void:
	# Directorios a incluir en el paquete de gráficos
	var asset_dirs = [
		{ "path": "res://Assets/Gfx/", "prefix": "Assets/Gfx/" },
		{ "path": "res://Resources/", "prefix": "Resources/" }
	]
	
	# Diccionario para almacenar archivos por directorio
	var all_files = {}
	var total_files = 0

	# Procesar cada directorio
	for dir_info in asset_dirs:
		var dir_path = dir_info["path"]
		var prefix = dir_info["prefix"]
		
		var dir = DirAccess.open(dir_path)
		if not dir:
			push_warning("No se pudo abrir el directorio: " + dir_path)
			continue
		
		var files = []
		var dirs_to_explore = [""]  # Empezar con el directorio raíz
		var dir_files_count = 0
		
		while not dirs_to_explore.is_empty():
			var current_dir = dirs_to_explore.pop_front()
			var full_dir = dir_path.path_join(current_dir) if current_dir else dir_path
			
			dir = DirAccess.open(full_dir)
			if not dir:
				continue
			
			dir.list_dir_begin()
			var file_name = dir.get_next()
			
			while file_name != "":
				var rel_path = current_dir.path_join(file_name) if current_dir else file_name
				
				if dir.current_is_dir():
					if file_name != "." and file_name != "..":
						dirs_to_explore.append(rel_path)
				else:
					# Incluir archivos de imagen y otros recursos gráficos
					var ext = file_name.get_extension().to_lower()
					if ext in ["png", "import", "tres"]:
						files.append(rel_path)
						dir_files_count += 1
						total_files += 1
						
						# Actualizar la interfaz periódicamente
						if total_files % 10 == 0:
							labelStatus.text = "Explorando recursos gráficos: %d archivos encontrados..." % total_files
							await get_tree().process_frame
				
				file_name = dir.get_next()
		
		all_files[dir_path] = {
			"prefix": prefix,
			"files": files
		}

	if total_files == 0:
		labelStatus.text = "No se encontraron archivos gráficos para empaquetar"
		return

	labelStatus.text = "Preparando para empaquetar %d archivos gráficos..." % total_files
	await get_tree().process_frame

	# Crear el archivo PCK
	var packer = PCKPacker.new()
	var output_path = "res://graphics.pck"
	
	if packer.pck_start(output_path) != OK:
		push_error("Error al crear el archivo PCK de gráficos")
		labelStatus.text = "Error al crear el archivo PCK de gráficos"
		return

	# Contador de archivos procesados
	var processed = 0
	
	# Agregar cada archivo al PCK
	for dir_path in all_files:
		var dir_info = all_files[dir_path]
		var file_prefix = dir_info["prefix"]
		var dir_files = dir_info["files"]
		
		for file_name in dir_files:
			var file_path = dir_path + file_name
			var relative_path = file_prefix + file_name  # Ruta relativa dentro del PCK
			
			processed += 1
			labelStatus.text = "Exportando gráficos... (%d/%d) %s" % [processed, total_files, file_name]
			await get_tree().process_frame
			
			# Usar _add_file_to_pack en lugar de packer.add_file directamente
			_add_file_to_pack(packer, file_path, relative_path)
	
	# Finalizar y guardar el PCK
	if packer.flush() == OK:
		labelStatus.text = "PCK de gráficos creado exitosamente: %s (%d archivos)" % [output_path, processed]
		print("Paquete de gráficos creado con éxito con %d archivos" % processed)
	else:
		labelStatus.text = "Error al guardar el archivo PCK de gráficos"
		push_error("Error al guardar el archivo PCK de gráficos")
