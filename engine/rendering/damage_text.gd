extends Node2D
class_name DamageText

const DAMAGE_LIFETIME_SECONDS = 1.0
const RISE_DISTANCE = 20.0

const DAMAGE_TYPE_PUNAL = 1
const DAMAGE_TYPE_NORMAL = 2
const DAMAGE_TYPE_CRITICO = 3
const DAMAGE_TYPE_FALLO = 4
const DAMAGE_TYPE_CURAR = 5
const DAMAGE_TYPE_TRABAJO = 6

var _damage_value: int = 0
var _damage_type: int = DAMAGE_TYPE_NORMAL
var _label: Label
var _started: bool = false

func setup(damage_value: int, damage_type: int) -> void:
	_damage_value = damage_value
	_damage_type = damage_type
	if is_inside_tree():
		_apply_text()
		_start_animation()

func _ready() -> void:
	_ensure_label()
	_apply_text()
	_start_animation()

func _ensure_label() -> void:
	if _label:
		return
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.z_index = 20
	_label.z_as_relative = false
	var settings = LabelSettings.new()
	settings.font_size = 14
	settings.outline_size = 4
	settings.outline_color = Color(0, 0, 0, 0.7)
	_label.label_settings = settings
	add_child(_label)

func _apply_text() -> void:
	if not _label:
		return
	_label.text = _build_text()
	_label.self_modulate = _get_color()

func _build_text() -> String:
	match _damage_type:
		DAMAGE_TYPE_CRITICO:
			return "%d!!" % _damage_value
		DAMAGE_TYPE_CURAR, DAMAGE_TYPE_TRABAJO:
			return "+%d" % _damage_value
		DAMAGE_TYPE_FALLO:
			return "Fallo"
		_:
			return "-%d" % _damage_value

func _get_color() -> Color:
	match _damage_type:
		DAMAGE_TYPE_PUNAL:
			return Color(0.85, 0.2, 0.85)
		DAMAGE_TYPE_CRITICO:
			return Color(1.0, 0.55, 0.1)
		DAMAGE_TYPE_FALLO:
			return Color(0.8, 0.8, 0.8)
		DAMAGE_TYPE_CURAR:
			return Color(0.2, 1.0, 0.2)
		DAMAGE_TYPE_TRABAJO:
			return Color(0.2, 0.9, 1.0)
		_:
			return Color(1.0, 0.2, 0.2)

func _start_animation() -> void:
	if _started:
		return
	_started = true
	var tween = create_tween()
	var target_pos = position + Vector2(0, -RISE_DISTANCE)
	tween.tween_property(self, "position", target_pos, DAMAGE_LIFETIME_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _label:
		tween.parallel().tween_property(_label, "modulate:a", 0.0, DAMAGE_LIFETIME_SECONDS)
		if _damage_type == DAMAGE_TYPE_PUNAL:
			_label.scale = Vector2.ONE * 1.2
			tween.parallel().tween_property(_label, "scale", Vector2.ONE, DAMAGE_LIFETIME_SECONDS * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(queue_free)
