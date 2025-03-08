extends CanvasLayer
class_name GameInput

const MerchantPanelScene = preload("uid://b5q8b0u4jmm2b")
const BankPanelScene = preload("uid://c4skiho4j6vjn")

@export var _inventoryContainer:InventoryContainer
@export var _consoleRichTextLabel:RichTextLabel
@export var _consoleInputLineEdit:LineEdit
@export var _camera:Camera2D

var _gameContext:GameContext
var _currentPanel:Node

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_HandleMouseInput(event)
	if event is InputEventKey:
		_HandleKeyEvent(event)		


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
	
func OpenMerchant() -> void:
	var merchantPanel = MerchantPanelScene.instantiate() as MerchantPanel
	_currentPanel = merchantPanel
	add_child(merchantPanel)
	
	merchantPanel.SetMerchantInventory(_gameContext.merchantInventory)
	merchantPanel.SetPlayerInventory(_gameContext.playerInventory)
	_gameContext.trading = true
	
func CloseMerchant() -> void:
	if _currentPanel:
		_currentPanel.queue_free()
	
	_gameContext.trading = false
	
func OpenBank() -> void:
	var bankPanel = BankPanelScene.instantiate() as BankPanel
	_currentPanel = bankPanel
	add_child(bankPanel)
	
	bankPanel.SetBankInventory(_gameContext.bankInventory)
	bankPanel.SetPlayerInventory(_gameContext.playerInventory)
	_gameContext.trading = true

func CloseBank() -> void:
	if _currentPanel:
		_currentPanel.queue_free()
	_gameContext.trading = false
	
func SetBankGold(gold:int) -> void:
	if _currentPanel && _currentPanel is BankPanel:
		_currentPanel.SetBankGold(gold)
		
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
				  
func _HandleKeyEvent(event:InputEventKey) -> void: 
	if event.pressed && event.keycode == KEY_ENTER:
		_consoleInputLineEdit.show() 
		_consoleInputLineEdit.grab_focus() 
	
func _OnConsoleInputTextSubmitted(newText: String) -> void:
	if newText.is_empty():
		return
	
	GameProtocol.WriteTalk(newText)
	_consoleInputLineEdit.text = ""
	_consoleInputLineEdit.visible = false
