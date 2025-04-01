extends CanvasLayer
class_name GameInput

const MerchantPanelScene = preload("uid://b5q8b0u4jmm2b")
const BankPanelScene = preload("uid://c4skiho4j6vjn")

@export var _inventoryContainer:InventoryContainer 
@export var _consoleRichTextLabel:RichTextLabel
@export var _consoleInputLineEdit:LineEdit
@export var _camera:Camera2D

@onready var minimap: Minimap = $Minimap
@onready var spell_list_panel: SpellListPanel = $"Inventory-Spell/SpellListPanel" 

@onready var experience_stat_bar: StatBar = $StatBars/ExperienceStatBar
@onready var stamina_stat_bar: StatBar = $StatBars/StaminaStatBar
@onready var health_stat_bar: StatBar = $StatBars/HealthStatBar
@onready var mana_stat_bar: StatBar = $StatBars/ManaStatBar 
@onready var thirst_stat_bar: StatBar = $StatBars/ThirstStatBar
@onready var hunger_stat_bar: StatBar = $StatBars/HungerStatBar 

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
				  
func _handle_key_event(event:InputEventKey) -> void: 
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
	if event.is_action_pressed("Meditate"):
		_meditate()
	if event.is_action_pressed("DropObject"):
		_drop_object()
	if event.is_action_pressed("Talk"):
		_talk()
	if event.is_action_pressed("TakeScreenShot"):
		_take_screenshot()
		
	
func _unhandled_key_input(event: InputEvent) -> void: 
	if event is InputEventKey:
		_handle_key_event(event)	
	
	
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


func _drop_object() -> void:
	if _gameContext.trading:
		return
	
	if !_gameContext.player_stats.is_alive():
		ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if _inventoryContainer.GetSelectedSlot() == -1:
		return
		
	_show_drop_panel(_inventoryContainer.GetSelectedSlot() + 1)

func _attack() -> void:
	GameProtocol.WriteAttack()

func _talk() -> void:
	if _consoleInputLineEdit.visible:
		return
	if _gameContext.trading:
		return
	
	_consoleInputLineEdit.show()
	_consoleInputLineEdit.grab_focus()
	

func _take_screenshot() -> void: 
	await RenderingServer.frame_post_draw
	
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	
	var now = Time.get_datetime_dict_from_system()
	var date_time = "%04d_%02d_%02d %02d_%02d_%02d" % [now.year, now.month, now.day, now.hour, now.minute, now.second]
	
	var path = "user://screenshots/%s.png" % date_time
	var absolute_path = ProjectSettings.globalize_path("user://screenshots/%s.png" % date_time) 
	
	if image.save_png(path) == OK:
		ShowConsoleMessage("[Screen] %s" % absolute_path, GameAssets.FontDataList[Enums.FontTypeNames.FontType_Dios]) 		
		
func _hide() -> void:
	GameProtocol.WriteWork(Enums.Skill.Ocultarse)

func _meditate() -> void:
	var stats = _gameContext.player_stats 
	
	if stats.mana == stats.max_mana:
		return
	
	if !stats.is_alive():
		ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
		
	GameProtocol.WriteMeditate()

func _on_main_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_HandleMouseInput(event)


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
 

func _on_btn_minimize_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func _on_btn_drop_gold_pressed() -> void:
	_show_drop_panel(Consts.Flagoro)
	

func _show_drop_panel(slot:int) -> void:
	var drop_panel = load("uid://c107vd41m3j3s").instantiate() 
	get_parent().add_child(drop_panel)
	
	drop_panel.slot = slot
	drop_panel.popup_centered()
