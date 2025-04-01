extends Node

	
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
			
func _ExportMaps() -> void:
	for fileName in Utils.GetFilesInDirectory("res://Assets/Maps/"):
		fileName = fileName.substr(4)
		fileName = fileName.substr(0, fileName.find("."))
		
		_ExportMap(int(fileName))
					
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
		ResourceSaver.save(packedScene, "res://Maps/Map%d.tscn" % fileId) 


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
	for i in range(1, GameAssets.BodyAnimationList.size()):
		var data = GameAssets.BodyAnimationList[i]
		var spriteFrames = SpriteFrames.new()
		
		spriteFrames.set_meta("offset_x", data.offsetX);
		spriteFrames.set_meta("offset_y", data.offsetY);
		
		spriteFrames.remove_animation("default")
		_AttachAnimation(spriteFrames, "west", data.west);
		_AttachAnimation(spriteFrames, "east", data.east);
		_AttachAnimation(spriteFrames, "south", data.south);
		_AttachAnimation(spriteFrames, "north", data.north);
		
		ResourceSaver.save(spriteFrames, "res://Resources/Character/Bodies/body_%d.tres" % i);	
	
func _Weapons() -> void:
	for i in range(1, GameAssets.WeaponAnimationList.size()):
		if i == Consts.NoAnim:
			continue
			
		var data = GameAssets.WeaponAnimationList[i]
		var spriteFrames = SpriteFrames.new()

		spriteFrames.remove_animation("default")
		_AttachAnimation(spriteFrames, "west", data.west);
		_AttachAnimation(spriteFrames, "east", data.east);
		_AttachAnimation(spriteFrames, "south", data.south);
		_AttachAnimation(spriteFrames, "north", data.north);
		
		ResourceSaver.save(spriteFrames, "res://Resources/Character/Weapons/weapon_%d.tres" % i);	

func _Shields() -> void:
	for i in range(1, GameAssets.ShieldAnimationList.size()):
		if i == Consts.NoAnim:
			continue
			
		var data = GameAssets.ShieldAnimationList[i]
		var spriteFrames = SpriteFrames.new()

		spriteFrames.remove_animation("default")
		_AttachAnimation(spriteFrames, "west", data.west);
		_AttachAnimation(spriteFrames, "east", data.east);
		_AttachAnimation(spriteFrames, "south", data.south);
		_AttachAnimation(spriteFrames, "north", data.north);
		
		ResourceSaver.save(spriteFrames, "res://Resources/Character/Shields/shield_%d.tres" % i);	
		
func _Heads() -> void:
	for i in range(1, GameAssets.HeadAnimationList.size()):
		var data = GameAssets.HeadAnimationList[i]
		var spriteFrames = SpriteFrames.new()
		
		if 0 in [data.east, data.north, data.south, data.west]:
			continue
			
		spriteFrames.remove_animation("default")
		_AttachHeadAnimation(spriteFrames, "west", data.west);
		_AttachHeadAnimation(spriteFrames, "east", data.east);
		_AttachHeadAnimation(spriteFrames, "south", data.south);
		_AttachHeadAnimation(spriteFrames, "north", data.north);
		
		ResourceSaver.save(spriteFrames, "res://Resources/Character/Heads/head_%d.tres" % i);	

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
