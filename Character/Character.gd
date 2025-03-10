extends Node2D
class_name Character

const Speed = 120.0

@export var renderer:CharacterRenderer
@export var _dialogLabel:Label
@export var _nameLabel:Label
@export var _dialogClearTimer:Timer

var _pasoDerecho:bool
var _targetPosition:Vector2
var _charInvisible:bool

var instanceId:int
var gridPosition:Vector2i
var isMoving:bool
var priv:int

func _physics_process(delta: float) -> void:
	_ProcessAnimation()
	_ProcessMovement(delta)

func GetCharacterInvisible() -> bool:
	return _charInvisible
	
func SetCharacterInvisible(v:bool) -> void:
	_charInvisible = v
	renderer.visible = v
	_nameLabel.visible = v

func MoveTo(heading:int) -> void:
	if isMoving:
		position = _targetPosition
		isMoving = false
	
	var offset = Utils.HeadingToVector(heading)
	isMoving = true
	_targetPosition = position + (offset * Consts.TileSize)
	
func StopMoving() -> void:
	if isMoving:
		position = _targetPosition
	isMoving = false
 
func GetBoundaries() -> Rect2:
	return Rect2(global_position.x - 16, global_position.y - 64, 32, 64)
		
func SetCharacterName(text:String) -> void:
	_nameLabel.text = text
	
func SetCharacterNameColor(color:Color) -> void:
	_nameLabel.self_modulate = color

func GetCharacterName() -> String:
	return _nameLabel.text

func IsDead() -> bool:
	return renderer.head in [Consts.CabezaCasper, Consts.CuerpoFragataFantasmal]
	
func IsNavigating() -> bool:
	return renderer.body in Consts.ShipIds
	
func PlayWalkSound() -> void:
	_pasoDerecho = !_pasoDerecho
	AudioManager.PlayAudio(Consts.Paso1 if _pasoDerecho else Consts.Paso2)
	
func PlayNavigationSound() -> void:
	AudioManager.PlayAudio(Consts.PasoNavegando);

func Say(text:String, color:Color) -> void:
	_dialogLabel.text = text
	_dialogLabel.modulate = color
	_dialogClearTimer.start()

func _OnDialogClearTimerTimeout() -> void:
	_dialogLabel.text = ""
	
func _ProcessAnimation() -> void:
	if isMoving:
		renderer.Play()
	else:
		renderer.Stop()

func _ProcessMovement(delta:float) -> void:
	if !isMoving:
		return
	
	position = position.move_toward(_targetPosition, Speed * delta)
	if position == _targetPosition:
		isMoving = false
