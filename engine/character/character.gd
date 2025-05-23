extends Node2D
class_name Character

const Speed = 120.0
const OUTLINE_SHADER = preload("res://shaders/outline.gdshader")
 
@onready var renderer: CharacterRenderer = $Renderer  
@onready var effect: CharacterEffect = $CharacterEffect

@export var _dialogLabel:Label
@export var _dialogShadowLabel:Label
@export var _nameLabel:Label
@export var _dialogClearTimer:Timer

var _pasoDerecho:bool
var _targetPosition:Vector2
var _charInvisible:bool
var _isPlayer:bool = false

var instanceId:int
var gridPosition:Vector2i
var isMoving:bool
var priv:int

func _ready() -> void:
	Global.connect("dialog_font_size_changed", Callable(self, "_on_dialog_font_size_changed"))
	if _isPlayer:
		_apply_outline_effect()

func _physics_process(delta: float) -> void:
	_ProcessAnimation()
	_ProcessMovement(delta)

func SetAsPlayer(isPlayer: bool = true) -> void:
	_isPlayer = isPlayer
	if isPlayer and is_inside_tree():
		_apply_outline_effect()

func IsPlayer() -> bool:
	return _isPlayer

func _apply_outline_effect() -> void:
	return 
	
	for child in renderer.get_children():
		if child is AnimatedSprite2D:
			var material = ShaderMaterial.new()
			material.shader = OUTLINE_SHADER
			# Configurar el color y ancho del borde
			material.set_shader_parameter("outline_color", Color(0.0, 0.5, 1.0, 0.7))  # Azul con transparencia
			material.set_shader_parameter("outline_width", 2.0)
			child.material = material

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
	_dialogLabel.label_settings.font_size = Global.dialogFontSize
	_dialogLabel.text = text
	_dialogShadowLabel.label_settings.font_size = _dialogLabel.label_settings.font_size
	_dialogShadowLabel.text = _dialogLabel.text
	_dialogLabel.modulate = color
	_dialogClearTimer.start()

func _OnDialogClearTimerTimeout() -> void:
	_dialogLabel.text = ""
	_dialogShadowLabel.text = ""
	
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

func _on_dialog_font_size_changed(value: int) -> void:
	_dialogLabel.label_settings.font_size = value
	_dialogShadowLabel.label_settings.font_size = value
