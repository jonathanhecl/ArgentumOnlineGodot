extends Node2D

# Rotación de fondo para la pantalla de login: muestra los mapas principales
# de las ciudades, recorriendo suavemente de esquina a esquina y haciendo
# crossfade entre mapas cada cierto tiempo.

@export var map_display_duration: float = 10.0  # segundos entre cambios
@export var crossfade_duration: float = 2.0
@export var pan_duration: float = 16.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _slot_nodes: Array[Node2D] = [Node2D.new(), Node2D.new()]
var _slot_pans: Array[Tween] = []
var _slot_corners: Array[int] = []

var _active_index: int = 0
var _current_map_id: int = -1
var _is_transitioning: bool = false

func _ready() -> void:
	_rng.randomize()

	_slot_pans.resize(2)
	_slot_corners.resize(2)
	_slot_corners.fill(-1)

	_slot_nodes[0].name = "SlotA"
	_slot_nodes[1].name = "SlotB"
	add_child(_slot_nodes[0])
	add_child(_slot_nodes[1])

	_current_map_id = _random_map_id()
	_load_map_into_slot(0, _current_map_id)
	_slot_nodes[0].modulate = Color.WHITE

	var start_corner := _random_corner()
	_slot_corners[0] = start_corner
	_slot_nodes[0].position = _corner_position(start_corner)
	var target := _random_corner(start_corner)
	_pan_slot(0, target)

	_start_cycle_timer()

func _start_cycle_timer() -> void:
	var tween := create_tween()
	tween.tween_callback(_start_transition).set_delay(map_display_duration)

func _start_transition() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	var inactive_index := 1 - _active_index
	var next_map_id := _random_map_id(_current_map_id)
	_load_map_into_slot(inactive_index, next_map_id)
	_current_map_id = next_map_id

	_slot_nodes[inactive_index].position = _slot_nodes[_active_index].position
	_slot_nodes[inactive_index].modulate = Color(1.0, 1.0, 1.0, 0.0)
	_slot_corners[inactive_index] = _slot_corners[_active_index]
	var target := _random_corner(_slot_corners[inactive_index])
	_pan_slot(inactive_index, target)

	_crossfade(_active_index, inactive_index)

func _crossfade(from_index: int, to_index: int) -> void:
	var tween := create_tween()
	tween.tween_property(_slot_nodes[from_index], "modulate", Color(1.0, 1.0, 1.0, 0.0), crossfade_duration)
	tween.parallel().tween_property(_slot_nodes[to_index], "modulate", Color.WHITE, crossfade_duration)
	tween.finished.connect(_on_crossfade_finished.bind(to_index, from_index), CONNECT_ONE_SHOT)

func _on_crossfade_finished(to_index: int, from_index: int) -> void:
	_active_index = to_index
	_is_transitioning = false

	_slot_nodes[from_index].modulate = Color(1.0, 1.0, 1.0, 0.0)
	if _slot_pans[from_index]:
		_slot_pans[from_index].kill()
		_slot_pans[from_index] = null
	for child in _slot_nodes[from_index].get_children():
		child.queue_free()

	_start_cycle_timer()

func _load_map_into_slot(slot_index: int, map_id: int) -> void:
	var slot := _slot_nodes[slot_index]
	for child in slot.get_children():
		child.queue_free()

	slot.modulate = Color.WHITE if slot_index == _active_index else Color(1.0, 1.0, 1.0, 0.0)

	var map_path := "res://Maps/Map%d.tscn" % map_id
	if not ResourceLoader.exists(map_path):
		push_warning("LoginBackgroundMap: map not found: %s" % map_path)
		return
	var packed := load(map_path) as PackedScene
	if not packed:
		push_warning("LoginBackgroundMap: failed to load map: %s" % map_path)
		return
	var map_instance := packed.instantiate()
	slot.add_child(map_instance)

func _pan_slot(slot_index: int, target_corner: int) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_slot_nodes[slot_index], "position", _corner_position(target_corner), pan_duration)
	tween.finished.connect(_on_pan_finished.bind(slot_index, target_corner), CONNECT_ONE_SHOT)
	_slot_pans[slot_index] = tween

func _on_pan_finished(slot_index: int, new_corner: int) -> void:
	_slot_corners[slot_index] = new_corner
	var next := _random_corner(new_corner)
	_pan_slot(slot_index, next)

func _random_map_id(exclude := -1) -> int:
	var ids: Array[int] = []
	ids.assign(Consts.HomeMapIds.values())
	if ids.is_empty():
		return 1
	if ids.size() == 1:
		return ids[0]
	var id := ids[_rng.randi() % ids.size()]
	while id == exclude:
		id = ids[_rng.randi() % ids.size()]
	return id

func _random_corner(exclude := -1) -> int:
	var corner := _rng.randi() % 4
	while corner == exclude:
		corner = _rng.randi() % 4
	return corner

func _corner_position(corner: int) -> Vector2:
	var screen := get_viewport().get_visible_rect().size
	var map_size := Vector2(Consts.MapSize * Consts.TileSize, Consts.MapSize * Consts.TileSize)
	match corner:
		0:
			return Vector2.ZERO
		1:
			return Vector2(screen.x - map_size.x, 0.0)
		2:
			return Vector2(screen.x - map_size.x, screen.y - map_size.y)
		3:
			return Vector2(0.0, screen.y - map_size.y)
	return Vector2.ZERO
