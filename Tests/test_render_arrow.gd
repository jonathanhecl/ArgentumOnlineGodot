extends Node2D
## Escena de pruebas de render para ArrowProjectile + StuckArrow.
## Ejecutar individualmente con F6 desde el editor, sin pasar por Main.
## Lanza flechas desde el centro hacia las 8 direcciones (para verificar rotacion)
## y en bucle alternando hit/miss contra un objetivo.

const CharacterScene = preload("uid://twhhld7du3lq")

const CENTER_POS := Vector2(960, 540)
const RADIUS := 380.0
const ARROW_GRH_ID := 752
const MAGIC_ARROW_GRH_ID := 609
const RELAUNCH_DELAY := 0.9

var _is_hit: bool = true
var _dir_index: int = 0
var _characters: Array = []

func _ready() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.11, 0.16, 0.09)
	bg.size = Vector2(1920, 1080)
	bg.z_index = -10
	add_child(bg)

	var map_scene = load("res://Maps/Map1.tscn")
	if map_scene:
		var map = map_scene.instantiate()
		map.z_index = -5
		add_child(map)

	var caster = _create_marker(CENTER_POS, Color(0.3, 0.6, 1.0))
	_create_targets()
	_launch_next(caster)

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

func _create_targets() -> void:
	var dirs = [
		Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1),
	]
	for d in dirs:
		var character = CharacterScene.instantiate() as Character
		add_child(character)
		character.position = CENTER_POS + d * RADIUS
		character.renderer.body = 1
		character.renderer.head = 1
		character.renderer.heading = Enums.Heading.South
		character.SetCharacterName("T")
		_characters.append(character)

func _launch_next(caster: Node2D) -> void:
	# Ronda 1: una flecha hacia cada dirección (todas acertando) para ver rotacion.
	if _dir_index < _characters.size():
		var projectile = ArrowProjectile.new()
		add_child(projectile)
		var target: Character = _characters[_dir_index]
		projectile.launch(ARROW_GRH_ID, caster, target)
		projectile.resolve_hit(true)
		_dir_index += 1
		await get_tree().create_timer(0.5).timeout
		_launch_next(caster)
		return
	# Ronda 2: en bucle alternando hit/miss contra el primer objetivo.
	var projectile = ArrowProjectile.new()
	add_child(projectile)
	var target: Character = _characters[0]
	var grh = ARROW_GRH_ID if _is_hit else MAGIC_ARROW_GRH_ID
	projectile.launch(grh, caster, target)
	projectile.resolve_hit(_is_hit)
	_is_hit = not _is_hit
	await get_tree().create_timer(RELAUNCH_DELAY).timeout
	_launch_next(caster)
