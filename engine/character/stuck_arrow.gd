extends Sprite2D
class_name StuckArrow

# Flecha clavada (en una criatura o en el piso). Permanece STUCK_DURATION segundos,
# con un leve temblor al clavarse y un fade-out al final. Es entidad runtime:
# el cache de mapas la libera al reciclar vistas.

const STUCK_DURATION := 10.0
const FADE_DURATION := 1.2
const WOBBLE_DURATION := 0.25
const WOBBLE_AMOUNT := 0.35 # radianes

var _elapsed_time: float = 0.0
var _fading: bool = false

func _ready() -> void:
	set_meta("is_runtime_entity", true)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true

# Configura la flecha clavada.
# grh_id: sprite de la flecha. flight_angle: rotacion visual que tenia en vuelo.
# base_angle: angulo base del sprite (para apuntar la punta).
# stuck_in_creature: si es true, se clava con la misma orientacion del vuelo
# (la punta apunta hacia adentro de la criatura); si es false (piso), la punta
# apunta hacia el suelo con una inclinacion natural.
func setup(grh_id: int, flight_angle: float, base_angle: float, stuck_in_creature: bool) -> void:
	var tex = GameAssets.GetGrhTexture(grh_id)
	if not tex:
		queue_free()
		return
	texture = tex
	
	if stuck_in_creature:
		# Mantiene la orientacion del impacto (la flecha "entra" en la criatura)
		rotation = flight_angle
	else:
		# Clavada en el piso: casi vertical, con una inclinacion aleatoria sutil
		var vertical_angle = -base_angle + PI * 0.5
		rotation = vertical_angle + deg_to_rad(randf_range(-12.0, 12.0))
	
	_play_wobble()

func _play_wobble() -> void:
	# Temblor corto al clavarse
	var tween = create_tween()
	var wobbles = 3
	for i in range(wobbles):
		tween.tween_property(self, "rotation", rotation + WOBBLE_AMOUNT, WOBBLE_DURATION / (wobbles * 2.0))
		tween.tween_property(self, "rotation", rotation - WOBBLE_AMOUNT, WOBBLE_DURATION / (wobbles * 2.0))
	tween.tween_property(self, "rotation", rotation, WOBBLE_DURATION / (wobbles * 2.0))

func _process(delta: float) -> void:
	if _fading:
		return
	_elapsed_time += delta
	if _elapsed_time >= STUCK_DURATION - FADE_DURATION:
		_fading = true
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
		tween.tween_callback(queue_free)
