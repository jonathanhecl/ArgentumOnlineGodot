extends Node2D
class_name MapContainer

const GridPositionKey = "GridPosition"
const CORE_VIEW_SIZE := Vector2(541, 413)
const CORE_RECT := Rect2(455, 170, 541, 413)
const FADE_DURATION := 0.4
const DOOR_SERVER_GRH_IDS: Array[int] = []
const MAP_SIZE_PX := 100 * 32 # 3200 px (un mapa completo de 100x100 tiles de 32px)
const NEIGHBOR_MODULATE := Color(0.88, 0.88, 0.92, 1.0) # Sutil atenuación para diferenciarlos

var _view:Node2D
var _current_map_id: int = 0
var _neighbor_views: Dictionary = {} # direction (String) -> Node2D

var _characterCollection:Array[Character]
var _objectCollection:Array[Node2D]
var _tiles:PackedByteArray
var _door_open_state_by_tile: Dictionary = {}

func _ready() -> void:
	print("🏗️ MapContainer: Inicializando contenedor de mapas...")
	_tiles.resize(100 * 100)
	_tiles.fill(Enums.TileState.Blocked)
	print("🏗️ MapContainer: Contenedor inicializado con ", _tiles.size(), " tiles bloqueados por defecto")

func _process(_delta: float) -> void:
	_update_entities_visibility()  
	
func LoadMap(id:int) -> void:
	print("🗺️ MapContainer: Iniciando carga del mapa ", id)
	_DeleteEntities()
	_door_open_state_by_tile.clear()
	_ClearNeighbors()
	
	if _view:
		print("🗺️ MapContainer: Liberando vista anterior del mapa")
		_view.queue_free()
	
	var map_path = "res://Maps/Map%d.tscn" % id
	print("🗺️ MapContainer: Buscando mapa en ruta: ", map_path)
	if not ResourceLoader.exists(map_path):
		push_error("MapContainer: Map file not found: %s" % map_path)
		return
		
	print("🗺️ MapContainer: Cargando escena del mapa...")
	_view = load(map_path).instantiate()
	if not _view:
		push_error("MapContainer: No se pudo instanciar el mapa: %s" % map_path)
		return
		
	print("🗺️ MapContainer: Obteniendo datos del mapa...")
	_tiles = _view.get_meta("data")
	if _tiles == null:
		push_error("MapContainer: El mapa no tiene metadatos 'data'")
		return
		
	print("🗺️ MapContainer: Agregando mapa a MapView...")
	%MapView.add_child(_view)
	_current_map_id = id
	_LoadNeighbors(id)
	print("✅ MapContainer: Mapa ", id, " cargado exitosamente con ", _tiles.size(), " tiles")

func RefreshNeighbors() -> void:
	# Permite volver a intentar cargar vecinos (p.ej. tras descubrir una conexión nueva).
	if _current_map_id <= 0:
		return
	_ClearNeighbors()
	_LoadNeighbors(_current_map_id)

const NEIGHBOR_Z_GROUND := -100  # Layer1/Layer2 del vecino: bien atrás (detrás del suelo activo)
const NEIGHBOR_Z_OBJECTS := 1    # Layer3 del vecino (árboles): ENCIMA del suelo activo.
                                 # Así los canopies que se extienden hacia el mapa activo se ven
                                 # completos sobre el pasto. Respeta el comportamiento AO clásico
                                 # (el árbol puede cubrir al pj cuando éste camina por detrás).

func _apply_neighbor_z_recursive(node: Node) -> void:
	# Aplica z_index absoluto según la capa:
	# - Layer1 / Layer2 (suelo del vecino) van al fondo (NEIGHBOR_Z_GROUND).
	# - Layer3 (árboles y objetos verticales) quedan encima del suelo del mapa activo
	#   para que sus canopies no se corten abruptamente al cruzar el borde.
	# Cualquier otro CanvasItem hereda z del padre (comportamiento por defecto).
	for child in node.get_children():
		if child is CanvasItem:
			var ci: CanvasItem = child
			match ci.name:
				"Layer1", "Layer2":
					ci.z_as_relative = false
					ci.z_index = NEIGHBOR_Z_GROUND
				"Layer3":
					ci.z_as_relative = false
					ci.z_index = NEIGHBOR_Z_OBJECTS
		_apply_neighbor_z_recursive(child)

func _ClearNeighbors() -> void:
	for dir_key in _neighbor_views.keys():
		var v = _neighbor_views[dir_key]
		if is_instance_valid(v):
			v.queue_free()
	_neighbor_views.clear()

func _LoadNeighbors(id: int) -> void:
	if not is_instance_valid(MapNeighbors):
		return
	const TILE_PX := 32
	for dir_key in MapNeighbors.ALL_DIRS:
		var info: Dictionary = MapNeighbors.get_neighbor_info(id, dir_key)
		if info.is_empty():
			continue
		var neighbor_id: int = int(info["id"])
		if neighbor_id <= 0 or neighbor_id == id:
			continue
		var path := "res://Maps/Map%d.tscn" % neighbor_id
		if not ResourceLoader.exists(path):
			continue
		var neighbor_view: Node = load(path).instantiate()
		if neighbor_view == null:
			continue
		if not (neighbor_view is Node2D):
			neighbor_view.queue_free()
			continue
		var view2d: Node2D = neighbor_view
		view2d.name = "NeighborMap_%s" % dir_key
		# dx/dy están en tiles (pueden ser negativos). Se multiplica por 32 para obtener pixels.
		view2d.position = Vector2(int(info["dx"]) * TILE_PX, int(info["dy"]) * TILE_PX)
		view2d.modulate = NEIGHBOR_MODULATE
		# El vecino es puramente decorativo: sin física, sin input, sin _process.
		view2d.process_mode = Node.PROCESS_MODE_DISABLED
		# Prioridad de dibujo: los vecinos SIEMPRE van por debajo del mapa activo y de
		# todas las entidades (pj, criaturas, ítems). Usamos z_index absoluto negativo
		# y lo aplicamos recursivamente a los hijos (Layer1/2/3) para anular cualquier
		# z local que pudieran haber heredado de la escena exportada.
		view2d.z_as_relative = false
		view2d.z_index = -100
		_apply_neighbor_z_recursive(view2d)
		%MapView.add_child(view2d)
		# Además, reordenamos el árbol para que los vecinos queden al principio y el
		# mapa activo quede como último hijo (se pinta por encima sin depender de z).
		%MapView.move_child(view2d, 0)
		_neighbor_views[dir_key] = view2d
	if not _neighbor_views.is_empty():
		print("🧭 MapContainer: vecinos cargados -> ", _neighbor_views.keys())

func GetTile(x:int, y:int) -> int:
	return _tiles[x + y * 100]
	
func SetTile(x:int, y:int, state:int) -> void:
	_tiles[x + y * 100] = state
	
func BlockTile(x:int, y:int) -> void:
	var tile = GetTile(x, y) | Enums.TileState.Blocked
	SetTile(x, y, tile) 
		
func UnblockTile (x:int, y:int) -> void:
	var tile = GetTile(x, y) & ~Enums.TileState.Blocked
	SetTile(x, y, tile) 

func AddCharacter(character:Character) -> void:
	_characterCollection.append(character)
	var layer = _GetLayer("Layer3")
	if layer:
		layer.add_child(character)
		_apply_initial_visibility(character)
	else:
		# Fallback: agregar directamente al MapContainer si el mapa no está cargado
		add_child(character)
		_apply_initial_visibility(character)
		push_warning("MapContainer: Layer3 not available, character added to MapContainer directly") 
		
func DeleteCharacter(instanceId:int) -> void:
	var character = GetCharacter(instanceId)
	if character:
		_characterCollection.erase(character)
		character.queue_free()
			
func GetCharacter(instanceId:int) -> Character:
	for node in _characterCollection:
		if node.instanceId == instanceId:
			return node
	return null
	
func GetCharacterAt(x:int, y:int) -> Character:
	for node in _characterCollection:
		if node.gridPosition == Vector2i(x, y):
			return node
	return null

func SetAllCharacterNamesVisible(names_visible:bool) -> void:
	for character in _characterCollection:
		character.SetNameVisible(names_visible)
	
func AddObject(grhId:int, x:int, y:int) -> void:
	if grhId > 0:
		if grhId >= GameAssets.GrhDataList.size():
			push_error("MapContainer: Error crítico - GrhId %d fuera de rango (Total cargados: %d). ¿Falta indexar o actualizar graficos.ind?" % [grhId, GameAssets.GrhDataList.size()])
			return

		if GameAssets.GrhDataList[grhId].frameCount > 1:
			grhId = GameAssets.GrhDataList[grhId].frames[1]
		
		var grhData = GameAssets.GrhDataList[grhId]
		var sprite = _CreateSprite(grhData, x - 1, y - 1)
		sprite.set_meta(GridPositionKey, Vector2i(x, y))
		sprite.set_meta("grh_id", grhId)
		sprite.set_meta("is_server_object", true)
		_objectCollection.append(sprite)
		
		var layer_name = "Layer2" if sprite.region_rect.size == Vector2(32, 32) else "Layer3"
		var layer = _GetLayer(layer_name)
		if layer:
			layer.add_child(sprite)
			_apply_initial_object_visibility(sprite)
		else:
			push_error("MapContainer: Cannot add object, %s not available" % layer_name)

func AddDamageText(damage_text: Node2D) -> void:
	var layer = _GetLayer("Layer3")
	if layer:
		layer.add_child(damage_text)
	else:
		add_child(damage_text)
		push_warning("MapContainer: Layer3 not available, damage text added to MapContainer directly")
	
func DeleteObject(x:int, y:int) -> void:
	var node:Node2D = null
	
	for object in _objectCollection:
		if object.get_meta(GridPositionKey) == Vector2i(x, y):
			node = object
			break
	
	if node:
		_objectCollection.erase(node)
		node.queue_free()

# DEBUG: Obtener información de objetos en una posición
func GetObjectsAt(x:int, y:int) -> Array[Dictionary]:
	var result:Array[Dictionary] = []
	
	for object in _objectCollection:
		if object.get_meta(GridPositionKey) == Vector2i(x, y):
			var info = {
				"grh_id": -1,
				"position": object.position,
				"grid_pos": Vector2i(x, y),
				"texture": ""
			}
			if object.texture:
				info["texture"] = object.texture.resource_path
			# Intentar obtener el GRH ID del nombre del nodo o metadata
			if object.has_meta("grh_id"):
				info["grh_id"] = object.get_meta("grh_id")
			result.append(info)
	
	return result

# DEBUG: Obtener personaje en una posición (ya existe GetCharacterAt pero este loguea más info)
func GetCharacterDebugInfo(x:int, y:int) -> Dictionary:
	var character = GetCharacterAt(x, y)
	if character:
		return {
			"instance_id": character.instanceId,
			"name": character.GetCharacterName(),
			"grid_pos": Vector2i(x, y),
			"position": character.position,
			"body": character.renderer.body if character.renderer else -1,
			"head": character.renderer.head if character.renderer else -1
		}
	return {}
	
func _DeleteEntities() -> void:
	_characterCollection.clear()
	_objectCollection.clear()

func _CreateSprite(grhData:GrhData, x:int, y:int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = GameAssets.GetTexture(grhData.fileId)
	sprite.position = Vector2((x * 32) + 16, (y * 32) + 32);
	sprite.region_enabled = true
	sprite.region_rect = grhData.region;
	sprite.offset = Vector2(0, -sprite.region_rect.size.y / 2);
	
	return sprite

func _update_entities_visibility() -> void:
	var viewport := get_viewport()
	if not viewport:
		return
	var camera := viewport.get_camera_2d()
	if not camera:
		return
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return
	for character in _characterCollection:
		if is_instance_valid(character):
			_check_entity_visibility(character, camera, viewport_size)
	for obj in _objectCollection:
		if is_instance_valid(obj):
			_check_object_visibility(obj, camera, viewport_size)

func _apply_initial_visibility(entity: CanvasItem) -> void:
	var viewport := get_viewport()
	if not viewport:
		return
	var camera := viewport.get_camera_2d()
	if not camera:
		return
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return
	var screen_pos := _world_to_screen(entity.global_position, camera, viewport_size)
	var is_in_core := CORE_RECT.has_point(screen_pos)
	entity.set_meta("_in_core", is_in_core)
	entity.modulate.a = 1.0 if is_in_core else 0.0

func _apply_initial_object_visibility(entity: CanvasItem) -> void:
	var viewport := get_viewport()
	if not viewport:
		return
	var camera := viewport.get_camera_2d()
	if not camera:
		return
	var viewport_size := viewport.get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return
	var screen_pos := _world_to_screen(entity.global_position, camera, viewport_size)
	var is_in_core := CORE_RECT.has_point(screen_pos)
	entity.set_meta("_in_core", is_in_core)
	if is_in_core:
		entity.modulate.a = 1.0
		return
	if _is_door_server_object(entity):
		entity.modulate.a = 1.0
		return
	entity.modulate.a = 0.0

func _check_entity_visibility(entity: CanvasItem, camera: Camera2D, viewport_size: Vector2) -> void:
	var screen_pos := _world_to_screen(entity.global_position, camera, viewport_size)
	var is_in_core := CORE_RECT.has_point(screen_pos)
	if not entity.has_meta("_in_core"):
		entity.set_meta("_in_core", is_in_core)
		entity.modulate.a = 1.0 if is_in_core else 0.0
		return
	var was_in_core: bool = entity.get_meta("_in_core", is_in_core)
	if is_in_core == was_in_core:
		return
	entity.set_meta("_in_core", is_in_core)
	_fade_entity(entity, 1.0 if is_in_core else 0.0)

func _check_object_visibility(entity: CanvasItem, camera: Camera2D, viewport_size: Vector2) -> void:
	if not entity.has_meta("_in_core"):
		_apply_initial_object_visibility(entity)
		return
	var screen_pos := _world_to_screen(entity.global_position, camera, viewport_size)
	var is_in_core := CORE_RECT.has_point(screen_pos)
	var was_in_core: bool = entity.get_meta("_in_core", is_in_core)
	if is_in_core == was_in_core:
		if not is_in_core and _is_door_server_object(entity):
			entity.modulate.a = 1.0
		return
	entity.set_meta("_in_core", is_in_core)
	if is_in_core:
		_fade_entity(entity, 1.0)
		return
	if _is_door_server_object(entity):
		_fade_entity(entity, 1.0)
		return
	_fade_entity(entity, 0.0)

func RegisterServerDoorState(tile_x: int, tile_y: int, blocked: bool) -> void:
	var tile := Vector2i(tile_x, tile_y)
	_door_open_state_by_tile[tile] = not blocked
	for obj in _objectCollection:
		if not is_instance_valid(obj):
			continue
		if obj.get_meta(GridPositionKey, Vector2i(-1, -1)) != tile:
			continue
		if not _is_door_server_object(obj):
			continue
		var is_in_core: bool = obj.get_meta("_in_core", true)
		if is_in_core:
			obj.modulate.a = 1.0
		else:
			obj.modulate.a = 1.0

func _is_door_server_object(entity: CanvasItem) -> bool:
	if not entity.get_meta("is_server_object", false):
		return false
	var grh_id: int = entity.get_meta("grh_id", -1)
	if grh_id in DOOR_SERVER_GRH_IDS:
		return true
	var tile: Vector2i = entity.get_meta(GridPositionKey, Vector2i(-1, -1))
	return _door_open_state_by_tile.has(tile)

func _is_door_open(entity: CanvasItem) -> bool:
	var tile: Vector2i = entity.get_meta(GridPositionKey, Vector2i(-1, -1))
	return _door_open_state_by_tile.get(tile, false)

func _world_to_screen(world_pos: Vector2, camera: Camera2D, viewport_size: Vector2) -> Vector2:
	return (world_pos - camera.global_position) / camera.zoom + (viewport_size * 0.5)

func _fade_entity(entity: CanvasItem, target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(entity, "modulate:a", target_alpha, FADE_DURATION)

func _GetLayer(layerName: String) -> Node2D:
	if not _view:
		push_error("MapContainer: _view is null, LoadMap() must be called first")
		return null
		
	for node in _view.get_children():
		if node.name == layerName: 
			return node
			
	push_error("MapContainer: layer %s not found" % layerName)
	return null
