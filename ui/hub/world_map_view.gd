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

const COLOR_MAP_BORDER := Color(0, 0, 0, 0.55)
const COLOR_CURRENT_BORDER := Color(0.2, 1, 0.2, 1)
const COLOR_HOVER_BORDER := Color(1, 1, 0, 1)
const COLOR_PLAYER_DOT := Color(1, 0.15, 0.15, 1)
const COLOR_MAP_ID := Color(1, 1, 1, 0.9)
const COLOR_MAP_ID_CURRENT := Color(0.2, 1, 0.2, 1)
const COLOR_ID_SHADOW := Color(0, 0, 0, 0.85)
# Los mapas no visitados se muestran oscurecidos (multiplica la miniatura) pero visibles.
const COLOR_UNVISITED := Color(0.28, 0.28, 0.28, 1)
# Teletransportes (TileExit): línea de puntos celeste con flecha hacia el destino.
const COLOR_TELEPORT := Color(0.3, 0.85, 1.0, 0.95)
const TRANSITIONS_PATH := "res://Assets/Init/map_transitions.json"
# Banda (en tiles) para considerar que un TileExit está sobre un borde del mapa.
const PASSAGE_BORDER_BAND := 16

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
var _last_mouse := Vector2.ZERO
var _pending_fit := false

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
	_occupied_cells.clear()
	_current_map_id = 0
	queue_redraw()

func show_map(current_map_id: int, player_tile: Vector2i) -> void:
	_build_layout(current_map_id)
	_current_map_id = current_map_id
	_player_tile = player_tile
	_hovered_map_id = 0
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
	# BFS sobre la adyacencia geográfica: los mapas con paso de mapa quedan lado a lado,
	# formando una estrella alrededor del mapa central.
	var start := center_map if all_ids.has(center_map) else int(all_ids[0])
	_bfs_layout(start, Vector2i.ZERO)
	# Mapas sin paso de mapa (solo teletransporte): anillo alrededor del clúster, no uno
	# debajo del otro.
	_place_disconnected_ring(all_ids)

# Clasifica cada par (mapa, destino) por la geometría de sus TileExit:
# - Paso de mapa: >=3 exits formando una línea sobre un borde -> adyacencia geográfica.
# - Teletransporte: pocos exits (1-2) o no alineados con un borde -> línea celeste de puntos.
func _build_connections(all_ids: Array) -> void:
	# Base: adyacencia geográfica conocida (seed del export + runtime por caminar).
	for raw_map in all_ids:
		var map_id := int(raw_map)
		for dir in MapNeighbors.ALL_DIRS:
			var info := MapNeighbors.get_neighbor_info(map_id, dir)
			var nid := int(info.get("id", 0))
			if nid > 0 and nid != map_id:
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
					seen_tp[key] = {"a": a, "b": b, "a_to_b": false, "b_to_a": false}
				if map_id == a:
					seen_tp[key]["a_to_b"] = true
				else:
					seen_tp[key]["b_to_a"] = true
	for key in seen_tp:
		var l: Dictionary = seen_tp[key]
		if _is_geo_pair(int(l["a"]), int(l["b"])):
			continue
		_teleport_links.append(l)

# Un paso de mapa es una línea de exits sobre un borde (>=3, mayoría en un mismo borde).
func _passage_direction(exits: Array) -> String:
	var east := 0
	var west := 0
	var south := 0
	var north := 0
	for e in exits:
		var x := int(e["x"])
		var y := int(e["y"])
		if x >= 101 - PASSAGE_BORDER_BAND:
			east += 1
		if x <= PASSAGE_BORDER_BAND:
			west += 1
		if y >= 101 - PASSAGE_BORDER_BAND:
			south += 1
		if y <= PASSAGE_BORDER_BAND:
			north += 1
	var threshold := maxi(3, int(ceil(float(exits.size()) * 0.5)))
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
	var head := 0
	while head < _ordered_maps.size():
		var map_id: int = _ordered_maps[head]
		head += 1
		var cell: Vector2i = _grid[map_id]
		for nid in _geo_neighbors.get(map_id, {}):
			if _grid.has(nid):
				continue
			var dir: String = _geo_neighbors[map_id][nid]
			var preferred: Vector2i = cell + DIR_OFFSET[dir]
			# El grafo puede tener offsets inconsistentes y dos mapas caerían en la misma
			# celda: buscar la celda libre más cercana para no solaparlos.
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

# Los mapas sin paso de mapa (solo teletransporte) se reparten en un anillo alrededor
# del clúster geográfico, formando una estrella en lugar de apilarse uno debajo del otro.
# Si una celda ya está ocupada, el mapa se desplaza radialmente hacia afuera (sin solapes).
func _place_disconnected_ring(all_ids: Array) -> void:
	var ring: Array = []
	for raw_id in all_ids:
		var map_id := int(raw_id)
		if not _grid.has(map_id):
			ring.append(map_id)
	if ring.is_empty():
		return
	var center := _cluster_center()
	var radius := maxf(_cluster_radius(center) + 3.0, float(ring.size()) / TAU + 1.0)
	var n := ring.size()
	for i in range(n):
		var angle := (float(i) / float(n)) * TAU
		var preferred: Vector2i = Vector2i(
			int(center.x + cos(angle) * radius),
			int(center.y + sin(angle) * radius)
		)
		var cell := _find_free_cell(preferred, _occupied_cells)
		_occupied_cells[_cell_key(cell)] = true
		var map_id := int(ring[i])
		_grid[map_id] = cell
		_ordered_maps.append(map_id)

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
	if _ordered_maps.is_empty():
		return
	# Miniaturas primero (fondo).
	for map_id in _ordered_maps:
		var rect := _get_map_rect(map_id)
		var tex := _get_texture(map_id)
		if tex:
			var tint := Color.WHITE if Global.is_map_visited(map_id) else COLOR_UNVISITED
			draw_texture_rect_region(tex, rect, _get_thumbnail_region(tex), tint)
	# Teletransportes: línea de puntos celeste con flecha hacia el destino.
	var tp_width := maxf(1.5, 2.0 * _zoom)
	var dash := maxf(2.0, 3.0 * _zoom)
	for link in _teleport_links:
		var ca := _get_map_rect(int(link["a"])).get_center()
		var cb := _get_map_rect(int(link["b"])).get_center()
		if bool(link["a_to_b"]) and bool(link["b_to_a"]):
			draw_dashed_line(ca, cb, COLOR_TELEPORT, tp_width, dash)
		elif bool(link["a_to_b"]):
			_draw_dotted_arrow(ca, cb, COLOR_TELEPORT, tp_width, dash)
		else:
			_draw_dotted_arrow(cb, ca, COLOR_TELEPORT, tp_width, dash)
	# Bordes e ids encima de las líneas.
	for map_id in _ordered_maps:
		var rect := _get_map_rect(map_id)
		draw_rect(rect, COLOR_MAP_BORDER, false, 1.0)
		_draw_map_id(map_id, rect, map_id == _current_map_id)
	if _grid.has(_current_map_id):
		var current_rect := _get_map_rect(_current_map_id)
		draw_rect(current_rect, COLOR_CURRENT_BORDER, false, 3.0)
		_draw_player_dot(current_rect)
	if _grid.has(_hovered_map_id):
		draw_rect(_get_map_rect(_hovered_map_id), COLOR_HOVER_BORDER, false, 2.0)

func _draw_dotted_arrow(from: Vector2, to: Vector2, color: Color, width: float, dash: float) -> void:
	draw_dashed_line(from, to, color, width, dash)
	var dir := to - from
	var length := dir.length()
	if length < 10.0:
		return
	var unit := dir / length
	var head_size := maxf(7.0, width * 4.0)
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
			_dragging = button_event.pressed
			_last_mouse = button_event.position
			accept_event()
		elif button_event.button_index == MOUSE_BUTTON_RIGHT and button_event.pressed:
			close_requested.emit()
			accept_event()
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		if _dragging:
			_pan += motion_event.position - _last_mouse
			_last_mouse = motion_event.position
			queue_redraw()
		_hovered_map_id = _map_at(motion_event.position)
		queue_redraw()
