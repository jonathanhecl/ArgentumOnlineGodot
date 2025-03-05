extends Node

func _ready() -> void:
	_ExportMaps()
	
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
