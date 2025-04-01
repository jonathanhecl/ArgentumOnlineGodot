extends TextureRect
class_name MerchantPanel

@export var _merchantInventoryContainer:InventoryContainer
@export var _playerInventoryContainer:InventoryContainer
@export var _infoLabel:Label

@export var _quantitySpinBox:SpinBox

var _merchantInventory:Inventory
var _playerInventory:Inventory

func _ready() -> void:
	_merchantInventoryContainer.slotPressed.connect(func(index:int):
		_UpdateInfo(_merchantInventory.GetSlot(index).item))
		
	_playerInventoryContainer.slotPressed.connect(func(index:int):
		_UpdateInfo(_playerInventory.GetSlot(index).item))

func SetMerchantInventory(inventory:Inventory) -> void:
	_merchantInventoryContainer.SetInventory(inventory)
	_merchantInventory = inventory
	
func SetPlayerInventory(inventory:Inventory) -> void:
	_playerInventoryContainer.SetInventory(inventory)
	_playerInventory = inventory
 
func _UpdateInfo(item:Item) -> void:
	var infoText = item.name
	if !infoText.is_empty():
		infoText += " 💰%d" % item.salePrice;
	
	if (item.IsWeapon()):
		infoText += "\n🗡️%d/%d" % [item.minHit, item.maxHit]
	if (item.IsArmour()):
		infoText += "\n🛡️%d/%d" % [item.maxDef, item.minDef]

	_infoLabel.text = infoText;

func _GetQuantity() -> int:
	return int(_quantitySpinBox.value)

func _OnBuyButtonPressed() -> void:
	if _merchantInventoryContainer.GetSelectedSlot() == -1: return
	GameProtocol.WriteCommerceBuy(_merchantInventoryContainer.GetSelectedSlot() + 1, _GetQuantity());

func _OnSellButtonPressed() -> void:
	if _playerInventoryContainer.GetSelectedSlot() == -1: return
	GameProtocol.WriteCommerceSell(_playerInventoryContainer.GetSelectedSlot() + 1, _GetQuantity());


func _on_btn_close_pressed() -> void:
	GameProtocol.WriteCommerceEnd()
