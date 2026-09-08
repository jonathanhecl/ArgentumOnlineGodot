extends Control
class_name WorldMapView

signal close_requested

const MAP_PX := 100.0
const MAP_TILE_SIZE := 100
# Las miniaturas .bmp traen ~10 px de contenido del mapa contiguo en cada borde;
# se recorta y escala el interior para que la unión entre mapas no se vea extraña.
const BORDER_PX := 10
const INNER_SIZE := MAP_TILE_SIZE - 2 * BORDER_PX
const THUMB_PATH := "res://Assets/minimap_thumbnails/%d.bmp"

const DIR_OFFSET: Dictionary[String, Vector2i] = {
	"N": Vector2i(0, -1),
	"S": Vector2i(0, 1),
	"E": Vector2i(1, 0),
	"W": Vector2i(-1, 0),
	"NE": Vector2i(1, -1),
	"NW": Vector2i(-1, -1),
	"SE": Vector2i(1, 1),
	"SW": Vector2i(-1, 1),
}

const COLOR_MAP_BACKGROUND := Color(0.035, 0.05, 0.06, 0.96)
const COLOR_MAP_BORDER := Color(0.65, 0.78, 0.78, 0.7)
const COLOR_CURRENT_BORDER := Color(0.35, 1, 0.45, 1)
const COLOR_SELECTED_BORDER := Color(1, 0.72, 0.2, 1)
const COLOR_HOVER_BORDER := Color(1, 0.9, 0.35, 1)
const COLOR_PLAYER_DOT := Color(1, 0.22, 0.18, 1)
const COLOR_MAP_ID := Color(1, 1, 1, 0.95)
const COLOR_MAP_ID_CURRENT := Color(0.55, 1, 0.6, 1)
const COLOR_ID_SHADOW := Color(0, 0, 0, 0.85)
# Los mapas no visitados se muestran atenuados, pero con suficiente luz para distinguir el terreno.
const COLOR_UNVISITED := Color(0.62, 0.66, 0.64, 1)
# Teletransportes (TileExit): colores según el sentido y el componente.
const COLOR_TP_TO_DUNGEON := Color(0.35, 0.95, 0.45, 0.34)
const COLOR_TP_TO_CONTINENT := Color(1.0, 0.58, 0.2, 0.34)
const COLOR_TP_INTERNAL := Color(0.35, 0.78, 0.9, 0.18)
const TRANSITIONS_PATH := "res://Assets/Init/map_transitions.json"
# Banda (en tiles) para considerar que un TileExit está sobre un borde del mapa.
const PASSAGE_BORDER_BAND := 15
const MIN_PASSAGE_EXITS := 1
const DISCONNECTED_GRID_SPACING := 2

const MIN_ZOOM := 0.15
const MAX_ZOOM := 3.0
const ZOOM_STEP := 1.1
# El mapa del mundo muestra TODOS los mapas del grafo (sin límite de saltos).

var _grid: Dictionary = {}
var _ordered_maps: Array[int] = []
var _teleport_links: Array = []
# _geo_neighbors[map_id][neighbor_id] = dirección (N/S/E/W...): adyacencia geográfica
# combinada (MapNeighbors + pasos de mapa detectados en los .inf).
var _geo_neighbors: Dictionary = {}
var _continent_maps: Dictionary = {}
var _occupied_cells: Dictionary = {}
var _transition_seed: Dictionary = {}
var _transition_seed_loaded := false
var _current_map_id := 0
var _player_tile := Vector2i(1, 1)
var _hovered_map_id := 0
var _texture_cache: Dictionary = {}

var _zoom := 1.0
var _pan := Vector2.ZERO
var _dragging := false
var _drag_start := Vector2.ZERO
var _drag_moved := false
var _last_mouse := Vector2.ZERO
var _selected_map_id := 0
var _pending_fit := false

@onready var _selection_info: Label = $SelectionInfo

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_on_resized)

func _on_resized() -> void:
	if _pending_fit:
		_fit_to_content()
		queue_redraw()

func clear_map() -> void:
	_grid.clear()
	_ordered_maps.clear()
	_teleport_links.clear()
	_geo_neighbors.clear()
	_continent_maps.clear()
	_occupied_cells.clear()
	_current_map_id = 0
	queue_redraw()

func show_map(current_map_id: int, player_tile: Vector2i) -> void:
	_build_layout(current_map_id)
	_current_map_id = current_map_id
	_player_tile = player_tile
	_hovered_map_id = 0
	_selected_map_id = 0
	_update_selection_info()
	_pending_fit = true
	_fit_to_content()
	queue_redraw()

func refresh(current_map_id: int, player_tile: Vector2i) -> void:
	if current_map_id == _current_map_id:
		_player_tile = player_tile
		queue_redraw()
	else:
		show_map(current_map_id, player_tile)

func update_player_position(player_tile: Vector2i) -> void:
	_player_tile = player_tile
	queue_redraw()

func get_current_map_id() -> int:
	return _current_map_id

func _build_layout(center_map: int) -> void:
	_grid.clear()
	_ordered_maps.clear()
	_teleport_links.clear()
	_geo_neighbors.clear()
	_continent_maps.clear()
	_occupied_cells.clear()
	_load_transition_seed()
	var all_ids := MapNeighbors.get_all_map_ids()
	# Mapas que sólo existen vía teletransporte (mazmorras/interiores): incluirlos en el
	# layout para que sus uniones se vean, aunque no tengan adyacencia geográfica.
	for raw_mid in _get_transition_map_ids():
		var mid := int(raw_mid)
		if not all_ids.has(mid):
			all_ids.append(mid)
	if all_ids.is_empty():
		return
	_build_connections(all_ids)
	# El mapa 1 es el ancla estable del continente; el mapa actual sólo controla el foco.
	var continent_root := 1 if all_ids.has(1) else (center_map if all_ids.has(center_map) else int(all_ids[0]))
	_bfs_layout(continent_root, Vector2i.ZERO)
	for map_id in _ordered_maps:
		_continent_maps[map_id] = true
	# Cada componente unido por pasos normales conserva su continuidad interna.
	_place_geographic_components(all_ids)
	# Mapas sin paso normal (sólo teletransporte): cuadrícula compacta aparte.
	_place_disconnected_grid(all_ids)

# Clasifica cada par (mapa, destino) por la geometría de sus TileExit:
# - Paso de mapa: exits que cruzan una franja de 15 tiles hacia el borde opuesto.
# - Teletransporte: exits interiores o no alineados con un borde opuesto.
func _build_connections(all_ids: Array) -> void:
	# Base: adyacencia geográfica conocida (seed del export + runtime por caminar).
	for raw_map in all_ids:
		var map_id := int(raw_map)
		for dir in MapNeighbors.ALL_DIRS:
			var info := MapNeighbors.get_neighbor_info(map_id, dir)
			var nid := int(info.get("id", 0))
			if nid > 0 and nid != map_id and _has_geographic_evidence(map_id, nid):
				_add_geo_neighbor(map_id, nid, dir)
	# Clasificar los TileExit reales de cada mapa.
	var seen_tp := {}
	for raw_map in all_ids:
		var map_id := int(raw_map)
		var by_dest := {}
		for exit_info in GameAssets.GetMapInf(map_id):
			var to_id := int(exit_info["dest_map"])
			if to_id <= 0 or to_id == map_id:
				continue
			by_dest[to_id] = by_dest.get(to_id, []) + [exit_info]
		for dest in by_dest:
			var to_id := int(dest)
			var dir := _passage_direction(by_dest[to_id])
			if dir != "":
				_add_geo_neighbor(map_id, to_id, dir)
			elif to_id in all_ids:
				var a := mini(map_id, to_id)
				var b := maxi(map_id, to_id)
				var key := "%d_%d" % [a, b]
				if not seen_tp.has(key):
					seen_tp[key] = {
						"a": a,
						"b": b,
						"a_to_b": false,
						"b_to_a": false,
						"a_to_b_exits": [],
						"b_to_a_exits": [],
					}
				if map_id == a:
					seen_tp[key]["a_to_b"] = true
					seen_tp[key]["a_to_b_exits"].append_array(by_dest[to_id])
				else:
					seen_tp[key]["b_to_a"] = true
					seen_tp[key]["b_to_a_exits"].append_array(by_dest[to_id])
	for key in seen_tp:
		var l: Dictionary = seen_tp[key]
		if _is_geo_pair(int(l["a"]), int(l["b"])):
			continue
		_teleport_links.append(l)

func _has_geographic_evidence(from_map: int, to_map: int) -> bool:
	return _has_geographic_exits(from_map, to_map) or _has_geographic_exits(to_map, from_map)

func _has_geographic_exits(from_map: int, to_map: int) -> bool:
	var exits_to_target: Array = []
	for exit_info in GameAssets.GetMapInf(from_map):
		if int(exit_info["dest_map"]) == to_map:
			exits_to_target.append(exit_info)
	return not exits_to_target.is_empty() and _passage_direction(exits_to_target) != ""

# Un paso de mapa es una línea de exits sobre un borde (>=5, mayoría en un mismo borde).
func _passage_direction(exits: Array) -> String:
	var east := 0
	var west := 0
	var south := 0
	var north := 0
	for e in exits:
		var x := int(e["x"])
		var y := int(e["y"])
		var dest_x := int(e["dest_x"])
		var dest_y := int(e["dest_y"])
		# Un cruce geográfico debe salir por un borde y llegar por el borde opuesto.
		# Sólo mirar x/y clasifica erróneamente muchos portales internos de dungeons.
		if x >= 101 - PASSAGE_BORDER_BAND and dest_x <= PASSAGE_BORDER_BAND:
			east += 1
		if x <= PASSAGE_BORDER_BAND and dest_x >= 101 - PASSAGE_BORDER_BAND:
			west += 1
		if y >= 101 - PASSAGE_BORDER_BAND and dest_y <= PASSAGE_BORDER_BAND:
			south += 1
		if y <= PASSAGE_BORDER_BAND and dest_y >= 101 - PASSAGE_BORDER_BAND:
			north += 1
	var threshold := maxi(MIN_PASSAGE_EXITS, int(ceil(float(exits.size()) * 0.5)))
	if east >= threshold:
		return "E"
	if west >= threshold:
		return "W"
	if south >= threshold:
		return "S"
	if north >= threshold:
		return "N"
	return ""

func _add_geo_neighbor(from_id: int, to_id: int, dir: String) -> void:
	_geo_neighbors[from_id] = _geo_neighbors.get(from_id, {})
	_geo_neighbors[from_id][to_id] = dir
	var opp := _opposite_dir(dir)
	_geo_neighbors[to_id] = _geo_neighbors.get(to_id, {})
	_geo_neighbors[to_id][from_id] = opp

func _opposite_dir(dir: String) -> String:
	match dir:
		"N": return "S"
		"S": return "N"
		"E": return "W"
		"W": return "E"
		"NE": return "SW"
		"NW": return "SE"
		"SE": return "NW"
		"SW": return "NE"
	return dir

func _is_geo_pair(a: int, b: int) -> bool:
	return _geo_neighbors.get(a, {}).has(b)

# Mapas que aparecen como origen o destino en los teletransportes del seed del export.
func _get_transition_map_ids() -> Array:
	var ids := {}
	for raw_key in _transition_seed:
		ids[int(raw_key)] = true
		for t in _transition_seed[raw_key]:
			ids[int(t)] = true
	return ids.keys()

func _bfs_layout(seed_id: int, seed_cell: Vector2i) -> void:
	if seed_id <= 0 or _grid.has(seed_id):
		return
	_grid[seed_id] = seed_cell
	_occupied_cells[_cell_key(seed_cell)] = true
	_ordered_maps.append(seed_id)

	# Resolver primero todo el grafo cardinal para que las rutas contiguas conserven
	# sus celdas esperadas antes de añadir las diagonales.
	var head := 0
	while head < _ordered_maps.size():
		var map_id: int = _ordered_maps[head]
		head += 1
		_place_neighbors(map_id, MapNeighbors.CARDINAL_DIRS)

	# Las diagonales completan el dibujo, pero nunca deben desplazar una conexión cardinal.
	var diagonal_head := 0
	while diagonal_head < _ordered_maps.size():
		var diagonal_map_id: int = _ordered_maps[diagonal_head]
		diagonal_head += 1
		_place_neighbors(diagonal_map_id, MapNeighbors.DIAGONAL_DIRS)

func _place_neighbors(map_id: int, directions: Array[String]) -> void:
	var cell: Vector2i = _grid[map_id]
	for dir in directions:
		for nid in _geo_neighbors.get(map_id, {}):
			if _geo_neighbors[map_id][nid] != dir or _grid.has(nid):
				continue
			var preferred: Vector2i = cell + DIR_OFFSET[dir]
			var final_cell := _find_free_cell(preferred, _occupied_cells)
			_grid[nid] = final_cell
			_occupied_cells[_cell_key(final_cell)] = true
			_ordered_maps.append(nid)

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

# Devuelve la celda libre más cercana a `near`, buscando en anillos concéntricos.
func _find_free_cell(near: Vector2i, occupied: Dictionary) -> Vector2i:
	if not occupied.has(_cell_key(near)):
		return near
	for radius in range(1, 24):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if maxi(abs(x), abs(y)) != radius:
					continue
				var cell := near + Vector2i(x, y)
				if not occupied.has(_cell_key(cell)):
					return cell
	return near

func _place_geographic_components(all_ids: Array) -> void:
	var continent_center := _cluster_center()
	var continent_radius := _cluster_radius(continent_center)
	var component_index := 0
	var ring_radius := int(ceil(continent_radius)) + 4

	for raw_id in all_ids:
		var map_id := int(raw_id)
		if _grid.has(map_id) or not _geo_neighbors.has(map_id):
			continue
		# Si el componente tiene un ancla de teletransporte ya colocada (p.ej. 286
		# sale a 168), ponerlo junto a ella para que el TP quede visible en vez de
		# perderse en un anillo lejano. Si no, anillo como antes.
		var preferred := _get_component_tp_preferred_cell(map_id)
		if preferred == Vector2i(2147483647, 2147483647):
			var angle := TAU * float(component_index) / 8.0
			preferred = Vector2i(
				int(round(continent_center.x + cos(angle) * ring_radius)),
				int(round(continent_center.y + sin(angle) * ring_radius))
			)
		var free_origin := _find_safe_tp_cell(preferred)
		_place_component_safely(map_id, free_origin)
		component_index += 1
		# Si este componente llenó su sector, ampliar el anillo para el siguiente.
		if component_index % 8 == 0:
			ring_radius = int(ceil(_cluster_radius(continent_center))) + 4

# Coloca un componente geográfico verificando que ningún miembro quede pegado a
# mapas de OTRO componente (ni al continente): los vecinos reales van juntos,
# pero componentes distintos deben flotar separados (>=2 celdas) o el mapa miente.
# Si el crecimiento por BFS toca algo ajeno, revierte y reintenta más lejos.
func _place_component_safely(map_id: int, preferred: Vector2i) -> void:
	var origin := _find_safe_tp_cell(preferred)
	for _attempt in range(4):
		var before := _ordered_maps.size()
		_bfs_layout(map_id, origin)
		var members: Array = _ordered_maps.slice(before)
		if members.is_empty():
			return
		if not _component_touches_foreign(members):
			return
		for mid in members:
			_occupied_cells.erase(_cell_key(_grid[int(mid)]))
			_grid.erase(int(mid))
			_ordered_maps.erase(int(mid))
		var continent_center := _cluster_center()
		var direction := Vector2(origin) - continent_center
		if direction.length_squared() < 0.25:
			direction = Vector2.RIGHT
		var step := direction.normalized() * 3.0
		origin = _find_safe_tp_cell(origin + Vector2i(int(round(step.x)), int(round(step.y))))
	# Último recurso: ubicar sin solapar (puede quedar pegado, pero visible).
	_bfs_layout(map_id, _find_safe_tp_cell(preferred))

# Devuelve true si alguna celda de `members` toca (Chebyshev <= 1) a un mapa que no es del grupo.
func _component_touches_foreign(members: Array) -> bool:
	var own := {}
	for mid in members:
		own[int(mid)] = true
	for mid in members:
		var cell: Vector2i = _grid[int(mid)]
		for other in _grid.keys():
			if own.has(int(other)):
				continue
			var ocell: Vector2i = _grid[other]
			if maxi(abs(cell.x - ocell.x), abs(cell.y - ocell.y)) <= 1:
				return true
	return false

# Origen preferido de un componente geográfico desconectado: junto a su ancla de
# teletransporte ya colocada (p.ej. el bloque 286-290 junto a 168). Retorna un
# centinela si ningún miembro tiene TP hacia un mapa ya colocado.
func _get_component_tp_preferred_cell(seed_id: int) -> Vector2i:
	var no_anchor := Vector2i(2147483647, 2147483647)
	var members := {}
	var queue: Array[int] = [seed_id]
	members[seed_id] = true
	var head := 0
	while head < queue.size():
		var mid: int = queue[head]
		head += 1
		for nid in _geo_neighbors.get(mid, {}):
			var n := int(nid)
			if not members.has(n):
				members[n] = true
				queue.append(n)
	var continent_anchor := 0
	var fallback_anchor := 0
	for link in _teleport_links:
		var a_id := int(link["a"])
		var b_id := int(link["b"])
		var outside := 0
		if members.has(a_id) and _grid.has(b_id) and not members.has(b_id):
			outside = b_id
		elif members.has(b_id) and _grid.has(a_id) and not members.has(a_id):
			outside = a_id
		if outside <= 0:
			continue
		if _continent_maps.has(outside):
			continent_anchor = outside
			break
		fallback_anchor = outside
	var anchor_id := continent_anchor if continent_anchor > 0 else fallback_anchor
	if anchor_id <= 0:
		return no_anchor
	var continent_center := _cluster_center()
	var anchor_cell: Vector2i = _grid[anchor_id]
	var direction := Vector2(anchor_cell) - continent_center
	if direction.length_squared() < 0.25:
		direction = Vector2.RIGHT
	var outward := Vector2i(sign(direction.x), sign(direction.y))
	if outward == Vector2i.ZERO:
		outward = Vector2i(1, 0)
	return anchor_cell + outward * 3

# Los mapas sin paso geográfico (solo teletransporte) se agrupan en una cuadrícula
# compacta para que las zonas subterráneas no formen un círculo alrededor del mundo.
func _place_disconnected_grid(all_ids: Array) -> void:
	var disconnected: Array = []
	for raw_id in all_ids:
		var map_id := int(raw_id)
		if not _grid.has(map_id):
			disconnected.append(map_id)
	if disconnected.is_empty():
		return

	disconnected.sort()
	var pending := disconnected.duplicate()
	var placed_from_tp := true
	while not pending.is_empty() and placed_from_tp:
		placed_from_tp = false
		for raw_id in pending.duplicate():
			var map_id := int(raw_id)
			var preferred := _get_tp_preferred_cell(map_id)
			if preferred == Vector2i(2147483647, 2147483647):
				continue
			var cell := _find_safe_tp_cell(preferred)
			_occupied_cells[_cell_key(cell)] = true
			_grid[map_id] = cell
			_ordered_maps.append(map_id)
			pending.erase(raw_id)
			placed_from_tp = true

	var min_cell := _content_min_cell()
	var max_cell := _content_max_cell()
	var columns := mini(6, maxi(3, int(ceil(sqrt(float(pending.size()))))))
	var start := Vector2i(max_cell.x + 2, min_cell.y)
	for i in range(pending.size()):
		var preferred := start + Vector2i(
			(i % columns) * DISCONNECTED_GRID_SPACING,
			floori(float(i) / float(columns)) * DISCONNECTED_GRID_SPACING
		)
		var cell := _find_free_cell(preferred, _occupied_cells)
		_occupied_cells[_cell_key(cell)] = true
		var map_id := int(pending[i])
		_grid[map_id] = cell
		_ordered_maps.append(map_id)

func _find_safe_tp_cell(preferred: Vector2i) -> Vector2i:
	if not _occupied_cells.has(_cell_key(preferred)) and not _touches_any_component(preferred):
		return preferred
	for radius in range(1, 16):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if maxi(abs(x), abs(y)) != radius:
					continue
				var candidate := preferred + Vector2i(x, y)
				if not _occupied_cells.has(_cell_key(candidate)) and not _touches_any_component(candidate):
					return candidate
	return _find_free_cell(preferred, _occupied_cells)

func _touches_continent(cell: Vector2i) -> bool:
	for raw_map_id in _continent_maps:
		var continent_cell: Vector2i = _grid[int(raw_map_id)]
		if maxi(abs(cell.x - continent_cell.x), abs(cell.y - continent_cell.y)) <= 1:
			return true
	return false

func _touches_any_component(cell: Vector2i) -> bool:
	for map_id in _ordered_maps:
		var component_cell: Vector2i = _grid[map_id]
		if maxi(abs(cell.x - component_cell.x), abs(cell.y - component_cell.y)) <= 1:
			return true
	return false

func _get_tp_preferred_cell(map_id: int) -> Vector2i:
	var no_anchor := Vector2i(2147483647, 2147483647)
	var continent_anchor := 0
	var fallback_anchor := 0
	for link in _teleport_links:
		var a_id := int(link["a"])
		var b_id := int(link["b"])
		var anchor_id := 0
		if a_id == map_id and _grid.has(b_id):
			anchor_id = b_id
		elif b_id == map_id and _grid.has(a_id):
			anchor_id = a_id
		if anchor_id <= 0:
			continue
		if _continent_maps.has(anchor_id):
			continent_anchor = anchor_id
			break
		fallback_anchor = anchor_id
	var anchor_id := continent_anchor if continent_anchor > 0 else fallback_anchor
	if anchor_id <= 0:
		return no_anchor

	var continent_center := _cluster_center()
	var anchor_cell: Vector2i = _grid[anchor_id]
	var direction := Vector2(anchor_cell) - continent_center
	if direction.length_squared() < 0.25:
		direction = Vector2.RIGHT
	var outward := Vector2i(sign(direction.x), sign(direction.y))
	if outward == Vector2i.ZERO:
		outward = Vector2i(1, 0)
	return _find_safe_tp_cell(anchor_cell + outward * 2)

func _cluster_center() -> Vector2:
	var min_cell := _content_min_cell()
	var max_cell := _content_max_cell()
	return Vector2((min_cell.x + max_cell.x) * 0.5, (min_cell.y + max_cell.y) * 0.5)

func _cluster_radius(center: Vector2) -> float:
	var radius := 0.0
	for map_id in _ordered_maps:
		radius = maxf(radius, Vector2(_grid[map_id]).distance_to(center))
	return radius

func _content_min_cell() -> Vector2i:
	var min_cell := Vector2i(0, 0)
	for map_id in _ordered_maps:
		var cell: Vector2i = _grid[map_id]
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
	return min_cell

func _content_max_cell() -> Vector2i:
	var max_cell := Vector2i(0, 0)
	for map_id in _ordered_maps:
		var cell: Vector2i = _grid[map_id]
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	return max_cell

# Seed fiel de teletransportes generado por el Exportador (map_transitions.json).
func _load_transition_seed() -> void:
	if _transition_seed_loaded:
		return
	_transition_seed_loaded = true
	if not ResourceLoader.exists(TRANSITIONS_PATH):
		return
	var txt := FileAccess.get_file_as_string(TRANSITIONS_PATH)
	if txt.is_empty():
		return
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) == TYPE_DICTIONARY:
		_transition_seed = data

func _fit_to_content() -> void:
	if _ordered_maps.is_empty():
		return
	var min_cell := Vector2i(0, 0)
	var max_cell := Vector2i(0, 0)
	for map_id in _ordered_maps:
		var cell: Vector2i = _grid[map_id]
		min_cell.x = mini(min_cell.x, cell.x)
		min_cell.y = mini(min_cell.y, cell.y)
		max_cell.x = maxi(max_cell.x, cell.x)
		max_cell.y = maxi(max_cell.y, cell.y)
	var content_size := Vector2(max_cell.x - min_cell.x + 1, max_cell.y - min_cell.y + 1) * MAP_PX
	var view := size
	if content_size.x <= 0 or content_size.y <= 0 or view.x <= 0 or view.y <= 0:
		return
	_zoom = clampf(minf(view.x / content_size.x, view.y / content_size.y) * 0.92, MIN_ZOOM, MAX_ZOOM)
	# Centrar en el mapa del jugador, no en el centro del clúster: así el mapa actual queda
	# en el medio y sus continuaciones a su alrededor (no al revés).
	var current_cell: Vector2i = _grid.get(_current_map_id, _grid.get(_ordered_maps[0], Vector2i.ZERO))
	var focus := (Vector2(current_cell) + Vector2(0.5, 0.5)) * MAP_PX
	_pan = view * 0.5 - focus * _zoom
	_pending_fit = false

func _world_to_local(point: Vector2) -> Vector2:
	return point * _zoom + _pan

func _get_map_rect(map_id: int) -> Rect2:
	var cell: Vector2i = _grid[map_id]
	var origin := _world_to_local(Vector2(cell) * MAP_PX)
	return Rect2(origin, Vector2(MAP_PX, MAP_PX) * _zoom)

func _get_texture(map_id: int) -> Texture2D:
	if _texture_cache.has(map_id):
		return _texture_cache[map_id]
	var path := THUMB_PATH % map_id
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_texture_cache[map_id] = tex
	return tex

func _get_thumbnail_region(texture: Texture2D) -> Rect2:
	var source_size := Vector2i(texture.get_size())
	var crop_size := Vector2i(INNER_SIZE, INNER_SIZE)
	if source_size.x <= crop_size.x or source_size.y <= crop_size.y:
		return Rect2(Vector2.ZERO, texture.get_size())
	var origin := (source_size - crop_size) / 2
	return Rect2(origin, crop_size)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_MAP_BACKGROUND, true)
	if _ordered_maps.is_empty():
		return
	# Miniaturas primero (fondo).
	for map_id in _ordered_maps:
		var rect := _get_map_rect(map_id)
		var tex := _get_texture(map_id)
		if tex:
			var tint := Color(1.12, 1.1, 1.04, 1) if Global.is_map_visited(map_id) else Color(0.82, 0.86, 0.82, 1)
			draw_texture_rect_region(tex, rect, _get_thumbnail_region(tex), tint)
	# Teletransportes: línea de puntos celeste con flecha hacia el destino.
	var tp_width := maxf(0.9, 1.1 * _zoom)
	var dash := maxf(2.0, 3.0 * _zoom)
	for link in _teleport_links:
		if bool(link["a_to_b"]):
			_draw_teleport_link(link, true, tp_width, dash)
		if bool(link["b_to_a"]):
			_draw_teleport_link(link, false, tp_width, dash)
	# Bordes e ids encima de las líneas.
	for map_id in _ordered_maps:
		var rect := _get_map_rect(map_id)
		draw_rect(rect, COLOR_MAP_BORDER, false, 1.0)
		_draw_map_id(map_id, rect, map_id == _current_map_id)
	if _grid.has(_current_map_id):
		var current_rect := _get_map_rect(_current_map_id)
		draw_rect(current_rect, COLOR_CURRENT_BORDER, false, 3.0)
		_draw_player_dot(current_rect)
	if _grid.has(_selected_map_id):
		draw_rect(_get_map_rect(_selected_map_id), COLOR_SELECTED_BORDER, false, 3.0)
	if _grid.has(_hovered_map_id) and _hovered_map_id != _selected_map_id:
		draw_rect(_get_map_rect(_hovered_map_id), COLOR_HOVER_BORDER, false, 2.0)

func _draw_teleport_link(link: Dictionary, from_is_a: bool, width: float, dash: float) -> void:
	var from_id := int(link["a"] if from_is_a else link["b"])
	var to_id := int(link["b"] if from_is_a else link["a"])
	var points := _get_teleport_points(link, from_is_a)
	var color := COLOR_TP_INTERNAL
	if _continent_maps.has(from_id) and not _continent_maps.has(to_id):
		color = COLOR_TP_TO_DUNGEON
	elif not _continent_maps.has(from_id) and _continent_maps.has(to_id):
		color = COLOR_TP_TO_CONTINENT
	_draw_dotted_arrow(points["from"], points["to"], color, width, dash)

func _get_tile_position(rect: Rect2, x: int, y: int) -> Vector2:
	var tx := clampi(x, BORDER_PX + 1, MAP_TILE_SIZE - BORDER_PX)
	var ty := clampi(y, BORDER_PX + 1, MAP_TILE_SIZE - BORDER_PX)
	var tile_f := Vector2(float(tx - (BORDER_PX + 1)), float(ty - (BORDER_PX + 1)))
	return rect.position + tile_f * (rect.size / float(INNER_SIZE - 1))

func _get_teleport_points(link: Dictionary, from_is_a: bool) -> Dictionary:
	var source_id := int(link["a"] if from_is_a else link["b"])
	var destination_id := int(link["b"] if from_is_a else link["a"])
	var exits: Array = link["a_to_b_exits"] if from_is_a else link["b_to_a_exits"]
	var source_sum := Vector2.ZERO
	var destination_sum := Vector2.ZERO
	for exit_info in exits:
		source_sum += Vector2(int(exit_info["x"]), int(exit_info["y"]))
		destination_sum += Vector2(int(exit_info["dest_x"]), int(exit_info["dest_y"]))
	var count := maxf(1.0, float(exits.size()))
	var source_tile := source_sum / count
	var destination_tile := destination_sum / count
	return {
		"from": _get_tile_position(_get_map_rect(source_id), int(round(source_tile.x)), int(round(source_tile.y))),
		"to": _get_tile_position(_get_map_rect(destination_id), int(round(destination_tile.x)), int(round(destination_tile.y))),
	}

func _draw_dotted_arrow(from: Vector2, to: Vector2, color: Color, width: float, dash: float) -> void:
	draw_dashed_line(from, to, color, width, dash)
	var dir := to - from
	var length := dir.length()
	if length < 10.0:
		return
	var unit := dir / length
	var head_size := maxf(5.0, width * 3.5)
	var base := to - unit * head_size
	var perp := Vector2(-unit.y, unit.x)
	draw_line(to, base + perp * head_size * 0.55, color, width)
	draw_line(to, base - perp * head_size * 0.55, color, width)

func _draw_map_id(map_id: int, rect: Rect2, is_current: bool) -> void:
	if rect.size.x < 12 or rect.size.y < 12:
		return
	var font_size := clampf(11.0 * _zoom, 6.0, 12.0)
	var pos := rect.position + Vector2(3, rect.size.y - 3)
	draw_string(ThemeDB.fallback_font, pos + Vector2(1, 1), str(map_id), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_ID_SHADOW)
	draw_string(ThemeDB.fallback_font, pos, str(map_id), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_MAP_ID_CURRENT if is_current else COLOR_MAP_ID)

func _draw_player_dot(rect: Rect2) -> void:
	var tx := clampi(_player_tile.x, BORDER_PX + 1, MAP_TILE_SIZE - BORDER_PX)
	var ty := clampi(_player_tile.y, BORDER_PX + 1, MAP_TILE_SIZE - BORDER_PX)
	var tile_f := Vector2(float(tx - (BORDER_PX + 1)), float(ty - (BORDER_PX + 1)))
	var center := rect.position + tile_f * (rect.size / float(INNER_SIZE - 1))
	draw_circle(center, maxf(3.0, 3.0 * _zoom), COLOR_PLAYER_DOT)
	draw_arc(center, maxf(6.0, 6.0 * _zoom), 0, TAU, 24, COLOR_PLAYER_DOT, 1.5)

func _map_at(point: Vector2) -> int:
	for map_id in _ordered_maps:
		if _get_map_rect(map_id).has_point(point):
			return map_id
	return 0

func _select_map(map_id: int) -> void:
	_selected_map_id = map_id
	_update_selection_info()
	queue_redraw()

func _update_selection_info() -> void:
	if not _selection_info:
		return
	if _selected_map_id <= 0:
		_selection_info.text = "Hacé clic en un mapa para ver sus entradas"
		return

	var geographic_sources: Array[String] = []
	for raw_source in _geo_neighbors:
		var source_id := int(raw_source)
		var neighbors: Dictionary = _geo_neighbors[source_id]
		if neighbors.has(_selected_map_id):
			geographic_sources.append("%d (%s)" % [source_id, str(neighbors[_selected_map_id])])
	geographic_sources.sort()

	var teleport_out: Array[String] = []
	var teleport_in: Array[String] = []
	for link in _teleport_links:
		var a_id := int(link["a"])
		var b_id := int(link["b"])
		if a_id == _selected_map_id and bool(link["a_to_b"]):
			teleport_out.append(str(b_id))
		elif b_id == _selected_map_id and bool(link["b_to_a"]):
			teleport_out.append(str(a_id))
		if b_id == _selected_map_id and bool(link["a_to_b"]):
			teleport_in.append(str(a_id))
		elif a_id == _selected_map_id and bool(link["b_to_a"]):
			teleport_in.append(str(b_id))
	teleport_out.sort()
	teleport_in.sort()

	var lines := ["Mapa %d" % _selected_map_id]
	lines.append("Caminos: %s" % (", ".join(geographic_sources) if not geographic_sources.is_empty() else "ninguno"))
	lines.append("Salidas TP: %s" % (", ".join(teleport_out) if not teleport_out.is_empty() else "ninguna"))
	lines.append("Entradas TP: %s" % (", ".join(teleport_in) if not teleport_in.is_empty() else "ninguna"))
	_selection_info.text = "\n".join(lines)

func _zoom_at(anchor: Vector2, factor: float) -> void:
	var new_zoom := clampf(_zoom * factor, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(new_zoom, _zoom):
		return
	var world_anchor := (anchor - _pan) / _zoom
	_zoom = new_zoom
	_pan = anchor - world_anchor * _zoom
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
			_zoom_at(button_event.position, ZOOM_STEP)
			accept_event()
		elif button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			_zoom_at(button_event.position, 1.0 / ZOOM_STEP)
			accept_event()
		elif button_event.button_index == MOUSE_BUTTON_LEFT:
			if button_event.pressed:
				_dragging = true
				_drag_start = button_event.position
				_drag_moved = false
				_last_mouse = button_event.position
			else:
				if not _drag_moved:
					_select_map(_map_at(button_event.position))
				_dragging = false
			accept_event()
		elif button_event.button_index == MOUSE_BUTTON_RIGHT and button_event.pressed:
			close_requested.emit()
			accept_event()
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		if _dragging:
			if motion_event.position.distance_to(_drag_start) > 6.0:
				_drag_moved = true
			_pan += motion_event.position - _last_mouse
			_last_mouse = motion_event.position
			queue_redraw()
		_hovered_map_id = _map_at(motion_event.position)
		queue_redraw()
