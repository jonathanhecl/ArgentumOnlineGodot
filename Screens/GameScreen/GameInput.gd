extends CanvasLayer
class_name GameInput

const MerchantPanelScene = preload("uid://b5q8b0u4jmm2b")
const BankPanelScene = preload("uid://c4skiho4j6vjn")

@export var _inventoryContainer:InventoryContainer
@export var _spellList:SpellList
@export var _consoleRichTextLabel:RichTextLabel
@export var _consoleInputLineEdit:LineEdit
@export var _camera:Camera2D

@onready var minimap: Minimap = $Minimap

var _gameContext:GameContext
var _currentPanel:Node

var _user_weapon_slot:int
var _user_shield_slot:int
var _user_helmet_slot:int
var _user_armor_slot:int

func Init(gameContext:GameContext) -> void:
	_gameContext = gameContext
	_inventoryContainer.SetInventory(_gameContext.playerInventory)
	_inventoryContainer.slotPressed.connect(func(_v): 
		_use_object())

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
		
func SetSpellName(index:int, text:String) -> void:
	_spellList.SetSlotText(index, text)
	
	
func update_agility_label(value:int) -> void:
	%LblAgility.text = str(value)
	
	
func update_strength_label(value:int) -> void:
	%LblStrength.text = str(value)
		

func update_gold_label(value:int) -> void:
	%LblGold.text = str(value)
	

func update_level_label(value:int) -> void:
	%LblLevel.text = str(value)
		

func update_name_label(value:String) -> void:
	%LblName.text = str(value)
	
	
func update_equipment_label(slot:int, item_stack:ItemStack) -> void:
	if item_stack.equipped:
		match item_stack.item.type:
			Enums.eOBJType.eOBJType_otWeapon:
				%LblWeapon.text = "%d/%d" % [item_stack.item.minHit, item_stack.item.maxHit]
				_user_weapon_slot = slot
			
			Enums.eOBJType.eOBJType_otESCUDO:
				%LblShield.text = "%d/%d" % [item_stack.item.minDef, item_stack.item.maxDef]
				_user_shield_slot = slot
			
			Enums.eOBJType.eOBJType_otArmadura:
				%LblArmor.text = "%d/%d" % [item_stack.item.minDef, item_stack.item.maxDef]
				_user_armor_slot = slot
			
			Enums.eOBJType.eOBJType_otCASCO:
				%LblHelmet.text = "%d/%d" % [item_stack.item.minDef, item_stack.item.maxDef]
				_user_helmet_slot = slot 
	else:
		match slot:
			_user_weapon_slot:
				%LblWeapon.text = "0/0"
				_user_weapon_slot = 0
			
			_user_shield_slot:
				%LblShield.text = "0/0"
				_user_shield_slot = 0
			
			_user_armor_slot:
				%LblArmor.text = "0/0"
				_user_armor_slot = 0
			
			_user_helmet_slot:
				%LblHelmet.text = "0/0"
				_user_helmet_slot = 0
	
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
		return
		
	if event.is_action_pressed("EquipObject"):
		_equip_object()
	if event.is_action_pressed("UseObject"):
		_use_object()
	if event.is_action_pressed("Pickup"):
		_pickup_object()
	if event.is_action_pressed("Attack"):
		_attack()
	if event.is_action_pressed("Hide"):
		_hide()
	
func _OnConsoleInputTextSubmitted(newText: String) -> void:
	if newText.is_empty():
		return
	
	GameProtocol.WriteTalk(newText)
	_consoleInputLineEdit.text = ""
	_consoleInputLineEdit.visible = false

func _equip_object() -> void:
	var slot = _inventoryContainer.GetSelectedSlot()
	if slot == -1 || _gameContext.trading: return

	GameProtocol.WriteEquipItem(slot + 1)

func _use_object() -> void:
	var slot = _inventoryContainer.GetSelectedSlot() 
	if slot == -1 || _gameContext.trading || _gameContext.pause: return
	GameProtocol.WriteUseItem(slot + 1)
	
	
func _pickup_object() -> void:
	GameProtocol.WritePickup()


func _attack() -> void:
	GameProtocol.WriteAttack()


func _hide() -> void:
	GameProtocol.WriteWork(Enums.Skill.Ocultarse)


func _on_main_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_HandleMouseInput(event)
	if event is InputEventKey:
		_HandleKeyEvent(event)		
