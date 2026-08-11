extends Node2D
class_name ArrowProjectile

# Flecha en vuelo disparada por un jugador (paquete Proyectil del servidor).
# Viaja en linea recta desde el atacante hasta el objetivo. Al llegar:
#  - si acerto (hit): el objetivo recibe una flecha clavada + reaccion fuerte
#  - si fallo (miss): la flecha se clava en el piso + reaccion leve
# La resolucion hit/miss la decide game_screen correlacionando con CreateDamage.

const FLIGHT_SPEED := 700.0 # pixeles por segundo
const MIN_FLIGHT_TIME := 0.15
const MAX_PROCESS_STEP: float = 1.0 / 30.0

var _target_ref: WeakRef
var _grh_id: int = 0
var _hit: bool = true
var _result_resolved: bool = false
var _start_pos: Vector2
var _arrival_pos: Vector2
var _elapsed_time: float = 0.0
var _is_launched: bool = false
var _sprite: AnimatedSprite2D

func _ready() -> void:
	set_meta("is_runtime_entity", true)
	z_index = 0
	z_as_relative = true

# Lanza la flecha desde el atacante hacia el objetivo.
# La resolucion hit/miss se setea luego via resolve_hit() (correlacionando con
# CreateDamage). Hasta entonces la flecha asume acierto si el target sigue vivo.
func launch(grh_id: int, attacker_char, target_char) -> void:
	_grh_id = grh_id
	_target_ref = weakref(target_char)
	_start_pos = attacker_char.global_position + Vector2(0, -Consts.TileSize * 0.5)
	
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = GameAssets.BuildSpriteFramesFromGrh(grh_id)
	if _sprite.sprite_frames == null:
		queue_free()
		return
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = true
	_sprite.play("default")
	add_child(_sprite)
	
	# Posicion inicial: empujar la flecha hacia atras del atacante para que "salga" del arco
	global_position = _start_pos
	_arrival_pos = _get_target_position()
	_update_rotation()
	_is_launched = true

# El servidor indico el resultado (via CreateDamage): true=acierto, false=fallo.
func resolve_hit(is_hit: bool) -> void:
	_hit = is_hit
	_result_resolved = true

func is_flying() -> bool:
	return _is_launched

func get_target_ref() -> WeakRef:
	return _target_ref

func _get_target_position() -> Vector2:
	var target_char = _target_ref.get_ref()
	if target_char and is_instance_valid(target_char) and target_char.is_inside_tree():
		return target_char.global_position + Vector2(0, -Consts.TileSize * 0.5)
	return _arrival_pos if _arrival_pos != Vector2.ZERO else global_position

func _process(delta: float) -> void:
	if not _is_launched:
		return
	delta = minf(delta, MAX_PROCESS_STEP)
	_elapsed_time += delta
	_arrival_pos = _get_target_position()
	
	var to_target = _arrival_pos - global_position
	var dist = to_target.length()
	if dist > 2.0:
		var step = FLIGHT_SPEED * delta
		if step >= dist:
			global_position = _arrival_pos
		else:
			global_position += to_target.normalized() * step
	_update_rotation()
	
	# Si el objetivo desaparece a mitad de vuelo, la flecha sigue hasta la ultima posicion
	var target_char = _target_ref.get_ref()
	var target_gone = not (target_char and is_instance_valid(target_char) and target_char.is_inside_tree())
	if (not target_gone and dist < 6.0) or (target_gone and _elapsed_time > 1.0):
		_on_arrival()
		queue_free()

func _update_rotation() -> void:
	var to_target = _arrival_pos - global_position
	if to_target.length_squared() > 1.0:
		var flight_angle = to_target.angle()
		var base_angle = GameAssets.GetGrhPointingAngle(_grh_id)
		_sprite.rotation = flight_angle - base_angle

func _on_arrival() -> void:
	_is_launched = false
	var target_char = _target_ref.get_ref()
	var target_valid = target_char and is_instance_valid(target_char) and target_char.is_inside_tree()
	
	# Si nunca llego la resolucion del servidor, asumimos acierto solo si el target sigue vivo
	if not _result_resolved:
		_hit = target_valid
	
	var impact_pos = global_position
	var flight_angle = _sprite.rotation if _sprite else 0.0
	var base_angle = GameAssets.GetGrhPointingAngle(_grh_id)
	
	if target_valid and _hit:
		# Acierto: flecha clavada en la criatura + temblor fuerte
		target_char.attach_stuck_arrow(_grh_id, flight_angle, base_angle)
		target_char.play_hit_reaction(true)
		
		# Si el personaje murio mientras viajaba la flecha (remocion diferida),
		# completar la animacion de muerte una vez que llegan todos los proyectiles
		if target_char.has_meta("pending_death_removal"):
			if not _has_other_incoming_projectiles(target_char):
				target_char.play_death_animation()
	else:
		# Fallo (o target desaparecido): flecha clavada en el piso + temblor leve
		_spawn_ground_stuck(impact_pos, flight_angle, base_angle)
		if target_valid:
			target_char.play_hit_reaction(false)
			if target_char.has_meta("pending_death_removal"):
				if not _has_other_incoming_projectiles(target_char):
					target_char.play_death_animation()

func _has_other_incoming_projectiles(character: Character) -> bool:
	var parent = get_parent()
	if parent == null:
		return false
	for child in parent.get_children():
		if child == self:
			continue
		if (child is SpellProjectile or child is ArrowProjectile) and child.is_flying():
			var target_ref = child.get_target_ref()
			if target_ref and target_ref.get_ref() == character:
				return true
	return false

func _spawn_ground_stuck(impact_pos: Vector2, flight_angle: float, base_angle: float) -> void:
	var stuck = StuckArrow.new()
	stuck.setup(_grh_id, flight_angle, base_angle, false)
	# La flecha clavada debe vivir en una capa persistente, no bajo este proyectil
	# (que se libera al impactar).
	var parent = _get_layer3()
	if not parent:
		parent = get_parent()
	if parent:
		parent.add_child(stuck)
		stuck.global_position = impact_pos

func _get_layer3() -> Node2D:
	var game_world = ProtocolHandler.game_world
	if game_world and game_world.GetMapContainer():
		return game_world.GetMapContainer()._GetLayer("Layer3")
	return null
