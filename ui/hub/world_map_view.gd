extends Control
class_name WorldMapView

signal close_requested

const MAP_PX := 100.0
const THUMB_PATH := "res://Assets/minimap_thumbnails/%d.bmp"

const DIR_OFFSET := {
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
const COLOR_EDGE := Color(1, 1, 1, 0.16)
const COLOR_EDGE_CURRENT := Color(1, 0.85, 0, 0.75)
const COLOR_PLAYER_DOT := Color(1, 0.15, 0.15, 1)
const COLOR_MAP_ID := Color(1, 1, 1, 0.9)
const COLOR_MAP_ID_CURRENT := Color(0.2, 1, 0.2, 1)
const COLOR_ID_SHADOW := Color(0, 0, 0, 0.85)

const MIN_ZOOM := 0.15
const MAX_ZOOM := 3.0
const ZOOM_STEP := 1.1
# Radio de expansión (en saltos) desde el mapa del jugador: muestra las continuaciones
# cercanas en vez de recorrer todo el componente conexo, que al centrar dejaba el mapa
# del jugador en una esquina rodeado de mapas lejanos.
const MAX_BFS_HOPS := 2

var _grid: Dictionary = {}
var _ordered_maps: Array[int] = []
var _edges: Array = []
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
	_edges.clear()
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
	_edges.clear()
	if center_map <= 0:
		return
	var edge_keys := {}
	var hops := {center_map: 0}
	_grid[center_map] = Vector2i.ZERO
	_ordered_maps.append(center_map)
	var head := 0
	while head < _ordered_maps.size():
		var map_id: int = _ordered_maps[head]
		head += 1
		var cell: Vector2i = _grid[map_id]
		var hop: int = hops[map_id]
		if hop >= MAX_BFS_HOPS:
			continue
		for dir in MapNeighbors.ALL_DIRS:
			var info := MapNeighbors.get_neighbor_info(map_id, dir)
			var nid := int(info.get("id", 0))
			if nid <= 0 or nid == map_id:
				continue
			var key := "%d_%d" % [mini(map_id, nid), maxi(map_id, nid)]
			if not edge_keys.has(key):
				edge_keys[key] = true
				_edges.append({"a": map_id, "b": nid})
			if not _grid.has(nid):
				_grid[nid] = cell + DIR_OFFSET[dir]
				hops[nid] = hop + 1
				_ordered_maps.append(nid)

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
	var crop_size := Vector2i(int(MAP_PX), int(MAP_PX))
	if source_size.x <= crop_size.x or source_size.y <= crop_size.y:
		return Rect2(Vector2.ZERO, texture.get_size())
	var origin := (source_size - crop_size) / 2
	return Rect2(origin, crop_size)

func _draw() -> void:
	if _ordered_maps.is_empty():
		return
	for edge in _edges:
		var a := _get_map_rect(int(edge["a"]))
		var b := _get_map_rect(int(edge["b"]))
		var is_current := int(edge["a"]) == _current_map_id or int(edge["b"]) == _current_map_id
		draw_line(a.get_center(), b.get_center(), COLOR_EDGE_CURRENT if is_current else COLOR_EDGE, 1.5 if is_current else 1.0)
	for map_id in _ordered_maps:
		var rect := _get_map_rect(map_id)
		var tex := _get_texture(map_id)
		if tex:
			draw_texture_rect_region(tex, rect, _get_thumbnail_region(tex))
		draw_rect(rect, COLOR_MAP_BORDER, false, 1.0)
		_draw_map_id(map_id, rect, map_id == _current_map_id)
	if _grid.has(_current_map_id):
		var current_rect := _get_map_rect(_current_map_id)
		draw_rect(current_rect, COLOR_CURRENT_BORDER, false, 3.0)
		_draw_player_dot(current_rect)
	if _grid.has(_hovered_map_id):
		draw_rect(_get_map_rect(_hovered_map_id), COLOR_HOVER_BORDER, false, 2.0)

func _draw_map_id(map_id: int, rect: Rect2, is_current: bool) -> void:
	if rect.size.x < 12 or rect.size.y < 12:
		return
	var font_size := clampf(11.0 * _zoom, 6.0, 12.0)
	var pos := rect.position + Vector2(3, rect.size.y - 3)
	draw_string(ThemeDB.fallback_font, pos + Vector2(1, 1), str(map_id), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_ID_SHADOW)
	draw_string(ThemeDB.fallback_font, pos, str(map_id), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_MAP_ID_CURRENT if is_current else COLOR_MAP_ID)

func _draw_player_dot(rect: Rect2) -> void:
	var tile_f := Vector2(maxi(_player_tile.x, 1) - 1, maxi(_player_tile.y, 1) - 1)
	var center := rect.position + tile_f * (rect.size / 100.0)
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
