extends CanvasLayer
class_name GameInput

@export var _inventoryContainer:InventoryContainer
@export var _consoleRichTextLabel:RichTextLabel
@export var _camera:Camera2D

var _gameContext:GameContext

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_HandleMouseInput(event)


func Init(gameContext:GameContext) -> void:
	_gameContext = gameContext
	_inventoryContainer.SetInventory(_gameContext.playerInventory)

func ShowConsoleMessage(message:String, fontData:FontData = FontData.new(Color.WHITE)) -> void:
	var bbcode = "[color=#%s]%s[/color]" % [fontData.color.to_html(), message]
	if fontData.italic:
		bbcode = "[i]%s[/i]" % bbcode;

	if fontData.bold:
		bbcode = "[b]%s[/b]" % bbcode;
	
	_consoleRichTextLabel.append_text(bbcode + "\n")


func _CameraTransformVector(vec:Vector2) -> Vector2:
	return _camera.get_canvas_transform().affine_inverse() * vec

func _HandleMouseInput(event:InputEventMouseButton) -> void:
	var tilePosition = Vector2i((_CameraTransformVector(event.position) / 32.0).ceil()) 
	
	if event.double_click:
		if !_gameContext.mirandoForo && !_gameContext.trading:
			GameProtocol.WriteDoubleClick(tilePosition.x, tilePosition.y)
	else:
		if event.pressed: 
			if _gameContext.usingSkill == 0:
				GameProtocol.WriteLeftClick(tilePosition.x, tilePosition.y)
			else:
				GameProtocol.WriteWorkLeftClick(tilePosition.x, tilePosition.y, _gameContext.usingSkill)
				_gameContext.usingSkill = 0
