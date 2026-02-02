extends Node2D
class_name GameWorld
const CharacterScene = preload("uid://twhhld7du3lq")
const DamageTextScene = preload("res://engine/rendering/damage_text.gd")

@export var _mapContainer:MapContainer

func GetMapContainer() -> MapContainer:
	return _mapContainer

func CreateCharacter(data:CharacterCreate) -> Character:
	_mapContainer.DeleteCharacter(data.charIndex)
	
	var character = CharacterScene.instantiate() as Character
	
	# Configurar datos básicos antes de agregar al árbol
	character.instanceId = data.charIndex
	character.position = Vector2((data.x - 1) * 32, (data.y - 1) * 32) + Vector2(16, 32)
	character.gridPosition = Vector2(data.x, data.y)
	character.priv = data.privileges
	
	# Agregar al árbol para que @onready se inicialice
	_mapContainer.AddCharacter(character)
	
	# Ahora renderer está disponible
	character.SetCharacterName(data.name)
	character.SetCharacterNameColor(Utils.GetNickColor(data.nickColor, data.privileges))
	character.renderer.body = data.body 
	character.renderer.head = data.head
	character.renderer.helmet = data.helmet
	character.renderer.weapon = data.weapon
	character.renderer.shield = data.shield
	character.renderer.heading = data.heading
	
	# Aplicar configuración global de visibilidad de nombres
	character.SetNameVisible(Global.show_player_names)
	
	return character
	
func MoveCharacter(instanceId:int, heading:int) -> void:
	var character = GetCharacter(instanceId);
	if !character: return
	
	var offset = Utils.HeadingToVector(heading)
	character.renderer.heading = heading
	character.gridPosition += Vector2i(offset)
	character.MoveTo(heading)
	
	if character.effect.effect_id >= 40 && character.effect.effect_id <= 49:
		character.effect.stop_effect()
	
	_PlayerWalkSound(character)
	
func GetCharacter(instanceId:int) -> Character:
	return _mapContainer.GetCharacter(instanceId)
	
func GetCharacterAt(x:int, y:int) -> Character:
	return _mapContainer.GetCharacterAt(x, y)
	
func DeleteCharacter(instanceId:int) -> void:
	_mapContainer.DeleteCharacter(instanceId)
	
func DeleteObject(x:int, y:int) -> void:
	_mapContainer.DeleteObject(x, y)

func AddObject(grhId:int, x:int, y:int) -> void:
	DeleteObject(x, y);
	_mapContainer.AddObject(grhId, x, y)

func AddDamageText(x: int, y: int, damage: int, damage_type: int) -> void:
	if not _mapContainer:
		return
	var damage_text = DamageTextScene.new()
	damage_text.position = Vector2((x - 1) * Consts.TileSize + 16, (y - 1) * Consts.TileSize + 16)
	damage_text.setup(damage, damage_type)
	_mapContainer.AddDamageText(damage_text)
	
func SwitchMap(id:int) -> void:
	print("🔄 GameWorld: Solicitando cambio al mapa ", id)
	if not _mapContainer:
		push_error("GameWorld: _mapContainer es nulo")
		return
	_mapContainer.LoadMap(id)

func _PlayerWalkSound(character:Character) -> void:
	if character.IsDead():
		return
	var camera = get_viewport().get_camera_2d()
	if Utils.GetCameraBounds(camera).intersects(character.GetBoundaries()):
		if character.IsNavigating():
			character.PlayNavigationSound()
		else:
			character.PlayWalkSound()
