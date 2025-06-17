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

func _createPkgMaps() -> void:
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

	labelStatus.text = "Exportando mapas y miniaturas PKG... (0/%d)" % total
	await get_tree().process_frame

	# Crear el archivo PKG
	var packer = PCKPacker.new()
	var output_path = "res://maps.pkg"
	
	if packer.pck_start(output_path) != OK:
		push_error("Error al crear el archivo PKG de mapas")
		labelStatus.text = "Error al crear el archivo PKG de mapas"
		return

	# Contador de archivos procesados
	var processed = 0

	# Agregar mapas al PKG
	for i in range(map_files.size()):
		var map_file = map_files[i]
		var map_path = "res://Maps/" + map_file
		var relative_path = "Maps/" + map_file  # Ruta relativa dentro del PKG
		
		processed += 1
		labelStatus.text = "Exportando mapas PKG... (%d/%d) %s" % [processed, total, map_file]
		await get_tree().process_frame
		
		if packer.add_file(relative_path, map_path) != OK:
			push_error("Error al agregar el archivo: " + map_file)
			continue

	# Agregar miniaturas al PKG
	for i in range(thumbnail_files.size()):
		var thumb_file = thumbnail_files[i]
		var thumb_path = "res://Assets/minimap_thumbnails/" + thumb_file
		var relative_path = "Assets/minimap_thumbnails/" + thumb_file
		
		processed += 1
		labelStatus.text = "Exportando miniaturas PKG... (%d/%d) %s" % [processed, total, thumb_file]
		await get_tree().process_frame
		
		if packer.add_file(relative_path, thumb_path) != OK:
			push_error("Error al agregar la miniatura: " + thumb_file)
			continue
	
	# Finalizar y guardar el PKG
	if packer.flush() == OK:
		labelStatus.text = "PKG creado exitosamente: %s (%d archivos)" % [output_path, processed]
		print("Paquete de mapas creado con éxito con %d archivos" % processed)
	else:
		labelStatus.text = "Error al guardar el archivo PKG"
		push_error("Error al guardar el archivo PKG")

func _createPkgUI() -> void:
	# Directorios a incluir en el paquete UI
	var asset_dirs = [
		{ "path": "res://Assets/Init/", "prefix": "Assets/Init/" },
		{ "path": "res://Assets/UI/", "prefix": "Assets/UI/" },
		{ "path": "res://Assets/Cursors/", "prefix": "Assets/Cursors/" },
		{ "path": "res://Assets/Fonts/", "prefix": "Assets/Fonts/" },
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

	# Crear el archivo PKG
	var packer = PCKPacker.new()
	var output_path = "res://ui.pkg"
	
	if packer.pck_start(output_path) != OK:
		push_error("Error al crear el archivo PKG de UI")
		labelStatus.text = "Error al crear el archivo PKG"
		return

	# Contador de archivos procesados
	var processed = 0
	
	# Agregar cada archivo al PKG
	for dir_path in all_files:
		var dir_info = all_files[dir_path]
		var file_prefix = dir_info["prefix"]
		var files = dir_info["files"]
		
		for file_name in files:
			var file_path = dir_path + file_name
			var relative_path = file_prefix + file_name  # Ruta relativa dentro del PKG
			
			processed += 1
			labelStatus.text = "Exportando UI... (%d/%d) %s" % [processed, total_files, file_name]
			await get_tree().process_frame
			
			if packer.add_file(relative_path, file_path) != OK:
				push_error("Error al agregar el archivo: " + file_path)
				continue
	
	# Finalizar y guardar el PKG
	if packer.flush() == OK:
		labelStatus.text = "PKG de UI creado exitosamente: %s (%d archivos)" % [output_path, processed]
		print("Paquete UI creado con éxito con %d archivos" % processed)
	else:
		labelStatus.text = "Error al guardar el archivo PKG de UI"
		push_error("Error al guardar el archivo PKG de UI")

func _createPkgSound() -> void:
	# Directorios a incluir en el paquete de sonidos
	var asset_dirs = [
		{ "path": "res://Assets/Sfx/", "prefix": "Assets/Sfx/" },
		{ "path": "res://Assets/Music/", "prefix": "Assets/Music/" }
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
					# Solo incluir archivos de audio
					var ext = file_name.get_extension().to_lower()
					if ext in ["wav", "ogg", "mp3", "mp4", "import"]:
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
		labelStatus.text = "No se encontraron archivos de audio para empaquetar"
		return

	labelStatus.text = "Preparando para empaquetar %d archivos de audio..." % total_files
	await get_tree().process_frame

	# Crear el archivo PKG
	var packer = PCKPacker.new()
	var output_path = "res://sound.pkg"
	
	if packer.pck_start(output_path) != OK:
		push_error("Error al crear el archivo PKG de sonidos")
		labelStatus.text = "Error al crear el archivo PKG de sonidos"
		return

	# Contador de archivos procesados
	var processed = 0
	
	# Agregar cada archivo al PKG
	for dir_path in all_files:
		var dir_info = all_files[dir_path]
		var file_prefix = dir_info["prefix"]
		var files = dir_info["files"]
		
		for file_name in files:
			var file_path = dir_path + file_name
			var relative_path = file_prefix + file_name  # Ruta relativa dentro del PKG
			
			processed += 1
			labelStatus.text = "Exportando sonidos... (%d/%d) %s" % [processed, total_files, file_name]
			await get_tree().process_frame
			
			if packer.add_file(relative_path, file_path) != OK:
				push_error("Error al agregar el archivo: " + file_path)
				continue
	
	# Finalizar y guardar el PKG
	if packer.flush() == OK:
		labelStatus.text = "PKG de sonidos creado exitosamente: %s (%d archivos)" % [output_path, processed]
		print("Paquete de sonidos creado con éxito con %d archivos" % processed)
	else:
		labelStatus.text = "Error al guardar el archivo PKG de sonidos"
		push_error("Error al guardar el archivo PKG de sonidos")


func _createPkgGrh() -> void:
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

	# Crear el archivo PKG
	var packer = PCKPacker.new()
	var output_path = "res://graphics.pkg"
	
	if packer.pck_start(output_path) != OK:
		push_error("Error al crear el archivo PKG de gráficos")
		labelStatus.text = "Error al crear el archivo PKG de gráficos"
		return

	# Contador de archivos procesados
	var processed = 0
	
	# Agregar cada archivo al PKG
	for dir_path in all_files:
		var dir_info = all_files[dir_path]
		var file_prefix = dir_info["prefix"]
		var dir_files = dir_info["files"]
		
		for file_name in dir_files:
			var file_path = dir_path + file_name
			var relative_path = file_prefix + file_name  # Ruta relativa dentro del PKG
			
			processed += 1
			labelStatus.text = "Exportando gráficos... (%d/%d) %s" % [processed, total_files, file_name]
			await get_tree().process_frame
			
			if packer.add_file(relative_path, file_path) != OK:
				push_error("Error al agregar el archivo: " + file_path)
				continue
	
	# Finalizar y guardar el PKG
	if packer.flush() == OK:
		labelStatus.text = "PKG de gráficos creado exitosamente: %s (%d archivos)" % [output_path, processed]
		print("Paquete de gráficos creado con éxito con %d archivos" % processed)
	else:
		labelStatus.text = "Error al guardar el archivo PKG de gráficos"
		push_error("Error al guardar el archivo PKG de gráficos")
