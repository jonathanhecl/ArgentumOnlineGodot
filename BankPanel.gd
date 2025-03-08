extends Panel
class_name BankPanel

@export var _bankInventoryContainer:InventoryContainer
@export var _playerInventoryContainer:InventoryContainer
@export var _infoLabel:Label 
@export var _quantitySpinBox:SpinBox

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
	_goldLabel.text = "🏦: " + str(gold)

func _OnClosePressed() -> void:
	GameProtocol.WriteBankEnd()

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

func _OnExtractButtonPressed() -> void:
	if _bankInventoryContainer.GetSelectedSlot() == -1: return
	GameProtocol.WriteBankExtractItem(_bankInventoryContainer.GetSelectedSlot() + 1, _GetQuantity());

func _OnDepositButtonPressed() -> void:
	if _playerInventoryContainer.GetSelectedSlot() == -1: return
	GameProtocol.WriteBankDepositItem(_playerInventoryContainer.GetSelectedSlot() + 1, _GetQuantity());

func _OnExtractGoldButtonPressed() -> void:
	GameProtocol.WriteBankExtractGold(_GetGoldQuantity())

func _OnDepositGoldButtonPressed() -> void:
	GameProtocol.WriteBankDepositGold(_GetGoldQuantity())
