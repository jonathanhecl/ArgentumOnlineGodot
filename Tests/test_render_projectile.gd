extends Node2D
## Escena de pruebas de render para SpellProjectile (luz, estela, orbe).
## Ejecutar individualmente con F6 desde el editor, sin pasar por Main.
## Relanza el proyectil en bucle ciclando los FX para probar distintos colores.

const CASTER_POS := Vector2(480, 720)
const TARGET_POS := Vector2(1440, 360)
const RELAUNCH_DELAY := 0.8
const FIRST_FX_ID := 1
const LAST_FX_ID := 50

var _caster: Node2D
var _target: Node2D
var _fx_id: int = FIRST_FX_ID

func _ready() -> void:
	# Fondo oscuro tipo pasto para que la luz aditiva se aprecie bien
	var bg = ColorRect.new()
	bg.color = Color(0.11, 0.16, 0.09)
	bg.size = Vector2(1920, 1080)
	bg.z_index = -10
	add_child(bg)

	_caster = _create_marker(CASTER_POS, Color(0.3, 0.6, 1.0))
	_target = _create_marker(TARGET_POS, Color(1.0, 0.35, 0.3))
	_launch_next()

func _create_marker(pos: Vector2, color: Color) -> Node2D:
	var marker = Node2D.new()
	marker.position = pos
	add_child(marker)
	var square = ColorRect.new()
	square.color = color
	square.size = Vector2(16, 16)
	square.position = Vector2(-8, -8)
	marker.add_child(square)
	return marker

func _launch_next() -> void:
	var projectile = SpellProjectile.new()
	add_child(projectile)
	projectile.launch(_fx_id, _caster, _target, _on_projectile_arrival)

func _on_projectile_arrival() -> void:
	_fx_id += 1
	if _fx_id > LAST_FX_ID:
		_fx_id = FIRST_FX_ID
	await get_tree().create_timer(RELAUNCH_DELAY).timeout
	_launch_next()
