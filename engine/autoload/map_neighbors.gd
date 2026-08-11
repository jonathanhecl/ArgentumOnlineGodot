extends Node
# Registro persistente de adyacencia entre mapas.
# Se descubre automáticamente cuando el viajero cruza un borde caminando.
# Puede sembrarse con un archivo en res://Assets/Init/map_neighbors.json con la forma:
# { "1": {"N": 0, "S": 213, "E": 5, "W": 4}, ... }  (0 = sin vecino conocido)

const SAVE_PATH := "user://map_neighbors.json"
const SEED_PATH := "res://Assets/Init/map_neighbors.json"

const N := "N"
const S := "S"
const E := "E"
const W := "W"
const NE := "NE"
const NW := "NW"
const SE := "SE"
const SW := "SW"
const CARDINAL_DIRS: Array[String] = [N, S, E, W]
const DIAGONAL_DIRS: Array[String] = [NE, NW, SE, SW]
const ALL_DIRS: Array[String] = [N, S, E, W, NE, NW, SE, SW]

# Offset por defecto (en tiles) de la posición del vecino relativa al mapa actual,
# cuando no se conoce el valor real descubierto en runtime. 100 tiles = stitching perfecto.
const DEFAULT_OFFSETS: Dictionary = {
	N:  Vector2i(0, -100),
	S:  Vector2i(0, 100),
	E:  Vector2i(100, 0),
	W:  Vector2i(-100, 0),
	NE: Vector2i(100, -100),
	NW: Vector2i(-100, -100),
	SE: Vector2i(100, 100),
	SW: Vector2i(-100, 100),
}

signal neighbors_updated(map_id: int)

# _connections[map_id][direction] = { "id": int, "dx": int, "dy": int } (dx/dy en tiles)
var _connections: Dictionary = {}

func _ready() -> void:
	_load()

func get_neighbor(map_id: int, direction: String) -> int:
	var info := get_neighbor_info(map_id, direction)
	return int(info.get("id", 0))

# Devuelve todos los ids de mapas con conexiones conocidas (seed + runtime).
func get_all_map_ids() -> Array:
	return _connections.keys()

# Devuelve {"id": int, "dx": int, "dy": int} con el offset del vecino (en tiles) o
# diccionario vacío si no se conoce. El offset por defecto se aplica aquí si sólo se
# guardó el id (formato legacy).
func get_neighbor_info(map_id: int, direction: String) -> Dictionary:
	if map_id <= 0 or not _connections.has(map_id):
		return {}
	var dict: Dictionary = _connections[map_id]
	if not dict.has(direction):
		return {}
	var entry: Variant = dict[direction]
	var default_offset: Vector2i = DEFAULT_OFFSETS.get(direction, Vector2i.ZERO)
	if typeof(entry) == TYPE_DICTIONARY:
		var id: int = int(entry.get("id", 0))
		if id <= 0:
			return {}
		return {
			"id": id,
			"dx": int(entry.get("dx", default_offset.x)),
			"dy": int(entry.get("dy", default_offset.y)),
		}
	var id_only := int(entry)
	if id_only <= 0:
		return {}
	return {"id": id_only, "dx": default_offset.x, "dy": default_offset.y}

func register(from_map: int, direction: String, to_map: int, dx: int = 0, dy: int = 0, use_default: bool = false) -> void:
	if from_map <= 0 or to_map <= 0 or from_map == to_map:
		return
	if not ALL_DIRS.has(direction):
		return
	var default_offset: Vector2i = DEFAULT_OFFSETS.get(direction, Vector2i.ZERO)
	if use_default:
		dx = default_offset.x
		dy = default_offset.y
	var changed := _set_if_new(from_map, direction, to_map, dx, dy)
	var opp := _opposite(direction)
	if opp != "":
		var reverse_changed := _set_if_new(to_map, opp, from_map, -dx, -dy)
		changed = changed or reverse_changed
	# Derivar diagonales para ambos mapas involucrados si hay evidencia suficiente.
	changed = _derive_diagonals_for(from_map) or changed
	changed = _derive_diagonals_for(to_map) or changed
	if changed:
		_save()
		emit_signal("neighbors_updated", from_map)
		emit_signal("neighbors_updated", to_map)

func _opposite(direction: String) -> String:
	match direction:
		N: return S
		S: return N
		E: return W
		W: return E
		NE: return SW
		NW: return SE
		SE: return NW
		SW: return NE
	return ""

# Intenta derivar las 4 diagonales de un mapa a partir de cardinales conocidos.
# Para NE: compara el id obtenido vía N→E vs E→N; si coinciden (o uno desconocido) se acepta.
# El offset se compone por suma vectorial: A.NE = A.N + N.E (o A.E + E.N).
func _derive_diagonals_for(map_id: int) -> bool:
	if map_id <= 0:
		return false
	var changed := false
	var cardinals := {
		N: get_neighbor_info(map_id, N),
		S: get_neighbor_info(map_id, S),
		E: get_neighbor_info(map_id, E),
		W: get_neighbor_info(map_id, W),
	}
	var diag_paths := {
		NE: [[N, E], [E, N]],
		NW: [[N, W], [W, N]],
		SE: [[S, E], [E, S]],
		SW: [[S, W], [W, S]],
	}
	for diag in diag_paths.keys():
		var paths: Array = diag_paths[diag]
		var resolved: Dictionary = {}
		for path in paths:
			var first_dir: String = path[0]
			var second_dir: String = path[1]
			var first_info: Dictionary = cardinals[first_dir]
			if first_info.is_empty():
				continue
			var second_info := get_neighbor_info(int(first_info["id"]), second_dir)
			if second_info.is_empty():
				continue
			var candidate := {
				"id": int(second_info["id"]),
				"dx": int(first_info["dx"]) + int(second_info["dx"]),
				"dy": int(first_info["dy"]) + int(second_info["dy"]),
			}
			if resolved.is_empty():
				resolved = candidate
			elif int(resolved["id"]) != candidate["id"]:
				resolved = {} # ambigüedad: ids distintos por caminos distintos
				break
		if not resolved.is_empty() and int(resolved["id"]) != map_id:
			var target_id := int(resolved["id"])
			var dx := int(resolved["dx"])
			var dy := int(resolved["dy"])
			changed = _set_if_missing(map_id, diag, target_id, dx, dy) or changed
			var opposite_dir := _opposite(diag)
			if opposite_dir != "":
				changed = _set_if_missing(target_id, opposite_dir, map_id, -dx, -dy) or changed
	return changed

func _set_if_new(map_id: int, direction: String, target: int, dx: int, dy: int) -> bool:
	var dict: Dictionary = _connections.get(map_id, {})
	var prev: Variant = dict.get(direction, null)
	var new_entry := {"id": target, "dx": dx, "dy": dy}
	if typeof(prev) == TYPE_DICTIONARY \
			and int(prev.get("id", 0)) == target \
			and int(prev.get("dx", 0)) == dx \
			and int(prev.get("dy", 0)) == dy:
		return false
	dict[direction] = new_entry
	_connections[map_id] = dict
	return true

func _set_if_missing(map_id: int, direction: String, target: int, dx: int, dy: int) -> bool:
	var dict: Dictionary = _connections.get(map_id, {})
	if dict.has(direction):
		return false
	dict[direction] = {"id": target, "dx": dx, "dy": dy}
	_connections[map_id] = dict
	return true

func _load() -> void:
	_connections.clear()
	# Base: seed generado por el Exportador (res://Assets/Init/map_neighbors.json).
	# El seed es autoritativo (deriva de los .inf del servidor): sus enlaces no deben
	# ser reemplazados por datos de runtime viejos que podrían clasificar mal un cruce
	# en esquina. El archivo del usuario SOLO rellena huecos (mapas sin .inf, offsets
	# descubiertos jugando) sin pisar lo que ya conoce el seed.
	var seed_count := _merge_from_file(SEED_PATH, true)
	var user_count := _merge_from_file(SAVE_PATH, false)
	_derive_all_diagonals()
	print("🧭 MapNeighbors: %d mapas con conexiones (seed: %d, user: %d)" % [
		_connections.size(), seed_count, user_count
	])

func _derive_all_diagonals() -> void:
	var changed := true
	while changed:
		changed = false
		var map_ids := _connections.keys()
		for map_id in map_ids:
			changed = _derive_diagonals_for(int(map_id)) or changed

func _merge_from_file(path: String, overwrite: bool = true) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		return 0
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("MapNeighbors: formato inválido en %s" % path)
		return 0
	var count := 0
	for k in data.keys():
		var map_id := int(str(k))
		var dirs: Variant = data[k]
		if typeof(dirs) != TYPE_DICTIONARY:
			continue
		var existing: Dictionary = _connections.get(map_id, {})
		for d in ALL_DIRS:
			if not dirs.has(d):
				continue
			var raw: Variant = dirs[d]
			var default_offset: Vector2i = DEFAULT_OFFSETS.get(d, Vector2i.ZERO)
			var entry := {}
			if typeof(raw) == TYPE_DICTIONARY:
				var neighbor_id := int(raw.get("id", 0))
				if neighbor_id > 0:
					entry = {
						"id": neighbor_id,
						"dx": int(raw.get("dx", default_offset.x)),
						"dy": int(raw.get("dy", default_offset.y)),
					}
			else:
				var neighbor_id := int(raw)
				if neighbor_id > 0:
					entry = {"id": neighbor_id, "dx": default_offset.x, "dy": default_offset.y}
			# Con overwrite=false el seed manda: sólo se rellena la dirección si aún no existe.
			if not entry.is_empty() and (overwrite or not existing.has(d)):
				existing[d] = entry
		if not existing.is_empty():
			_connections[map_id] = existing
			count += 1
			for d in existing.keys():
				var entry: Dictionary = existing[d]
				var target_id := int(entry.get("id", 0))
				var opposite_dir := _opposite(str(d))
				if target_id > 0 and opposite_dir != "":
					_set_if_missing(target_id, opposite_dir, map_id, -int(entry.get("dx", 0)), -int(entry.get("dy", 0)))
	return count

func _save() -> void:
	var out: Dictionary = {}
	for k in _connections.keys():
		out[str(k)] = _connections[k]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("MapNeighbors: no se pudo abrir %s para escritura" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(out, "  "))
