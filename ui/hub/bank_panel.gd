extends TextureRect
class_name BankPanel

@export var _bankInventoryContainer:InventoryContainer
@export var _playerInventoryContainer:InventoryContainer
@export var _infoLabel:Label
@export var _itemIcon:TextureRect
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
	
	_quantitySpinBox.value_changed.connect(func(_value:float):
		# No necesitamos actualizar info en el banco, solo en comercio
		pass)
	
	# Desactivar tooltips en la ventana del banco
	InventorySlot.SetTooltipsEnabled(false)
	
	# Habilitar el mouse filter del label para que pueda mostrar tooltips
	_infoLabel.mouse_filter = Control.MOUSE_FILTER_STOP

func _exit_tree() -> void:
	# Reactivar tooltips al cerrar la ventana
	InventorySlot.SetTooltipsEnabled(true)


func SetBankInventory(inventory:Inventory) -> void:
	_bankInventoryContainer.SetInventory(inventory)
	_bankInventory = inventory
	
	
func SetPlayerInventory(inventory:Inventory) -> void:
	_playerInventoryContainer.SetInventory(inventory)
	_playerInventory = inventory


func SetBankGold(gold:int) -> void:
	_lbl_gold.text = str(gold)
  

func _UpdateInfo(item:Item) -> void:
	if item == null or item.name.is_empty():
		_infoLabel.text = ""
		_itemIcon.texture = null
		_infoLabel.tooltip_text = ""
		return
	
	# Mostrar el icono del ítem
	_itemIcon.texture = item.icon
	
	# Truncar solo el nombre del ítem si es muy largo (más de 18 caracteres)
	var itemName = item.name
	var displayName = itemName
	var maxNameLength = 18
	
	if itemName.length() > maxNameLength:
		displayName = itemName.substr(0, maxNameLength) + "..."
	
	var infoText = displayName
	
	if item.IsWeapon():
		infoText += "\n⚔️ %d-%d" % [item.minHit, item.maxHit]
	elif item.IsArmour():
		infoText += "\n🛡️ %d-%d" % [item.minDef, item.maxDef]
	
	_infoLabel.text = infoText
	
	# Tooltip solo con el nombre completo del ítem si fue truncado
	if itemName.length() > maxNameLength:
		_infoLabel.tooltip_text = itemName
	else:
		_infoLabel.tooltip_text = ""

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

# Manejar eventos de teclado para bloquear acciones del juego
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_btn_close_pressed()
			get_viewport().set_input_as_handled()
		else:
			# Consumir TODOS los eventos de teclado cuando la ventana está abierta
			get_viewport().set_input_as_handled()
