extends Node2D
class_name CharacterRenderer

const DefaultSpriteFramePath = "uid://750ochum2vjs"

@export var _verticalAlign:bool

@export var _bodyAnimatedSprite:AnimatedSprite2D
@export var _headAnimatedSprite:AnimatedSprite2D
@export var _helmetAnimatedSprite:AnimatedSprite2D
@export var _weaponAnimatedSprite:AnimatedSprite2D
@export var _shieldAnimatedSprite:AnimatedSprite2D

var _body:int
var _head:int
var _helmet:int
var _weapon:int
var _shield:int
var _bodyShadowSprite: AnimatedSprite2D

const SHADOW_OFFSET := Vector2(8, 10)
const SHADOW_SCALE := Vector2(1.0, 0.52)
const SHADOW_SKEW := -0.7853982
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.38)

var heading:int = Enums.Heading.South

func _ready() -> void:
	_setup_shadow_sprite()
	if not Global.shadows_visibility_changed.is_connected(_on_shadows_visibility_changed):
		Global.shadows_visibility_changed.connect(_on_shadows_visibility_changed)
	_on_shadows_visibility_changed(Global.show_shadows)

func _exit_tree() -> void:
	if Global.shadows_visibility_changed.is_connected(_on_shadows_visibility_changed):
		Global.shadows_visibility_changed.disconnect(_on_shadows_visibility_changed)

var body:int:
	get:
		return _body
	set(value):
		_set_body(value)

var head: int:
	get:
		return _head
	set(value):
		_set_head(value)

var helmet: int:
	get:
		return _helmet
	set(value):
		_set_helmet(value)

var weapon: int:
	get:
		return _weapon
	set(value):
		_set_weapon(value)

var shield: int:
	get:
		return _shield
	set(value):
		_set_shield(value)

func Play() -> void:
	var key = _get_heading_key()
	var opposite_key = _get_opposite_key(key)
	
	_play_directional_animation(_bodyAnimatedSprite, "walk_", key, opposite_key)
	_play_directional_animation(_bodyShadowSprite, "walk_", key, opposite_key)
	_play_directional_animation(_shieldAnimatedSprite, "walk_", key, opposite_key)
	_play_directional_animation(_weaponAnimatedSprite, "walk_", key, opposite_key)
	_play_directional_animation(_headAnimatedSprite, "idle_", key, opposite_key)
	_play_directional_animation(_helmetAnimatedSprite, "idle_", key, opposite_key)
	
func Stop() -> void:
	var key = _get_heading_key()
	var opposite_key = _get_opposite_key(key)
	
	_play_directional_animation(_bodyAnimatedSprite, "idle_", key, opposite_key)
	_play_directional_animation(_bodyShadowSprite, "idle_", key, opposite_key)
	_play_directional_animation(_shieldAnimatedSprite, "idle_", key, opposite_key)
	_play_directional_animation(_weaponAnimatedSprite, "idle_", key, opposite_key)
	_play_directional_animation(_headAnimatedSprite, "idle_", key, opposite_key)
	_play_directional_animation(_helmetAnimatedSprite, "idle_", key, opposite_key)

func _play_directional_animation(sprite: AnimatedSprite2D, prefix: String, key: String, opposite_key: String) -> void:
	if not sprite:
		return
	if not sprite.sprite_frames:
		return
		
	var anim_name = prefix + key
	var opposite_anim_name = prefix + opposite_key
	
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
		sprite.flip_h = false
	elif sprite.sprite_frames.has_animation(opposite_anim_name):
		sprite.play(opposite_anim_name)
		sprite.flip_h = true
	else:
		# Fallback a sur si no hay ni la dirección ni su opuesta
		# Esto evita que desaparezca, aunque la dirección sea incorrecta
		var fallback = prefix + "south"
		if sprite.sprite_frames.has_animation(fallback):
			sprite.play(fallback)
			sprite.flip_h = false

func _get_heading_key() -> String:
	var keys = Enums.Heading.keys()
	if heading >= 0 and heading < keys.size():
		return keys[heading].to_lower()
	return "south"  # Default fallback

func _get_opposite_key(key: String) -> String:
	match key:
		"east": return "west"
		"west": return "east"
		"north": return "south"
		"south": return "north"
	return "south"


func _set_weapon(id:int) -> void:
	_weapon = id 
	_weaponAnimatedSprite.sprite_frames = _LoadSpriteFrames("res://Resources/Character/Weapons/weapon_%d.tres" % id)

func _set_shield(id:int) -> void:
	_shield = id
	_shieldAnimatedSprite.sprite_frames = _LoadSpriteFrames("res://Resources/Character/Shields/shield_%d.tres" % id)

func _set_helmet(id:int) -> void:
	_helmet = id
	_helmetAnimatedSprite.sprite_frames = _LoadSpriteFrames("res://Resources/Character/Helmets/helmet_%d.tres" % id)

func _set_head(id:int) -> void:
	_head = id
	_headAnimatedSprite.sprite_frames = _LoadSpriteFrames("res://Resources/Character/Heads/head_%d.tres" % id)
	
	# Special correction for ghost head - raise it higher
	if id == Consts.CabezaCasper:
		var current_pos = _headAnimatedSprite.position
		_headAnimatedSprite.position = Vector2(current_pos.x, current_pos.y - 8)

func _set_body(id:int) -> void:
	_body = id
	_bodyAnimatedSprite.sprite_frames = _LoadSpriteFrames("res://Resources/Character/Bodies/body_%d.tres" % id)
	if _bodyShadowSprite:
		_bodyShadowSprite.sprite_frames = _bodyAnimatedSprite.sprite_frames
	
	# Apply head offset for different body types (enanos, gomos, etc.)
	if id > 0 and id < GameAssets.BodyAnimationList.size():
		var body_data = GameAssets.BodyAnimationList[id]
		var head_offset = Vector2(body_data.offsetX, body_data.offsetY)
		if head_offset.y <= 0:
			head_offset.y -= 2
		_headAnimatedSprite.position = head_offset
		_helmetAnimatedSprite.position = head_offset
	
	# Special correction for ghost bodies - raise head to human adult height
	if id == Consts.CuerpoFragataFantasmal or id in Consts.ShipIds:
		# Position head at normal human height (approximately -5 pixels from body center)
		var ghost_head_offset = Vector2(0, -5)
		_headAnimatedSprite.position = ghost_head_offset
		_helmetAnimatedSprite.position = ghost_head_offset
	
	if _verticalAlign:
		if _bodyAnimatedSprite.sprite_frames.get_frame_count("idle_south"):
			var offset_y = _bodyAnimatedSprite \
				.sprite_frames \
				.get_frame_texture("idle_south", 0) \
				.get_height() / 2.0
			position = Vector2(position.x, -offset_y)

func _LoadSpriteFrames(path:String) -> SpriteFrames:
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path)
	else:
		return ResourceLoader.load(DefaultSpriteFramePath)

func _setup_shadow_sprite() -> void:
	if not _bodyAnimatedSprite:
		return
	
	_bodyShadowSprite = AnimatedSprite2D.new()
	_bodyShadowSprite.name = "BodyShadow"
	_bodyShadowSprite.centered = _bodyAnimatedSprite.centered
	_bodyShadowSprite.offset = _bodyAnimatedSprite.offset
	_bodyShadowSprite.position = _bodyAnimatedSprite.position + SHADOW_OFFSET
	_bodyShadowSprite.scale = SHADOW_SCALE
	_bodyShadowSprite.skew = SHADOW_SKEW
	_bodyShadowSprite.modulate = SHADOW_COLOR
	_bodyShadowSprite.z_index = -100
	_bodyShadowSprite.sprite_frames = _bodyAnimatedSprite.sprite_frames
	add_child(_bodyShadowSprite)
	move_child(_bodyShadowSprite, 0)

func _on_shadows_visibility_changed(shadows_visible: bool) -> void:
	if _bodyShadowSprite:
		_bodyShadowSprite.visible = shadows_visible
