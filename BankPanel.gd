extends TextureRect
class_name BankPanel

@export var _bankInventoryContainer:InventoryContainer
@export var _playerInventoryContainer:InventoryContainer
@export var _infoLabel:Label 
@export var _quantitySpinBox:SpinBox

@onready var _lbl_gold: Label = $LblGold

@export var _goldLabel:Label
@export var _quantityGoldSpinBox:SpinBox

var _bankInventory:Inventory
var _playerInventory:Inventory

func _ready() -> void:
	_bankInventoryContainer.slotPressed.connect(func(index:int):
		_UpdateInfo(_bankInventory.GetSlot(index).item))
		
	_playerInventoryContainer.slotPressed.connect(func(index:int):
		_UpdateInfo(_playerInventory.GetSlot(index).item))


func SetBankInventory(inventory:Inventory) -> void:
	_bankInventoryContainer.SetInventory(inventory)
	_bankInventory = inventory
	
	
func SetPlayerInventory(inventory:Inventory) -> void:
	_playerInventoryContainer.SetInventory(inventory)
	_playerInventory = inventory


func SetBankGold(gold:int) -> void:
	_lbl_gold.text = str(gold)
  

func _UpdateInfo(item:Item) -> void:
	var infoText = item.name 
	
	if (item.IsWeapon()):
		infoText += "\n🗡️%d/%d" % [item.minHit, item.maxHit]
	if (item.IsArmour()):
		infoText += "\n🛡️%d/%d" % [item.maxDef, item.minDef]

	_infoLabel.text = infoText;

func _GetQuantity() -> int:
	return int(_quantitySpinBox.value)

func _GetGoldQuantity() -> int:
	return int(_quantityGoldSpinBox.value)


func _on_btn_close_pressed() -> void:
	GameProtocol.WriteBankEnd()
 

func _on_btn_extract_gold_pressed() -> void:
	GameProtocol.WriteBankExtractGold(_GetGoldQuantity())


func _on_btn_deposit_gold_pressed() -> void:
	GameProtocol.WriteBankDepositGold(_GetGoldQuantity())


func _on_btn_extract_pressed() -> void:
	if _bankInventoryContainer.GetSelectedSlot() == -1: return
	GameProtocol.WriteBankExtractItem(_bankInventoryContainer.GetSelectedSlot() + 1, _GetQuantity());


func _on_btn_deposit_pressed() -> void:
	if _playerInventoryContainer.GetSelectedSlot() == -1: return
	GameProtocol.WriteBankDepositItem(_playerInventoryContainer.GetSelectedSlot() + 1, _GetQuantity());
