extends Window
class_name MerchantPanel

@export var _merchantInventoryContainer:InventoryContainer
@export var _playerInventoryContainer:InventoryContainer
@export var _infoLabel:Label
@export var _itemIcon:TextureRect

@export var _quantitySpinBox:SpinBox
@export var _actionButton:Button
@export var _presetsContainer:HBoxContainer

const _PRESET_STEPS:Array[int] = [100, 1000, 10000]
const _PRESET_LABELS:Array[String] = ["100", "1K", "10K"]

var _presetButtons:Array[Button] = []

var _merchantInventory:Inventory
var _playerInventory:Inventory
var _selectedItem:Item = null
var _isFromMerchant:bool = false

func _ready() -> void:
	_merchantInventoryContainer.slotPressed.connect(func(index:int):
		_playerInventoryContainer.ClearSelection()
		_selectedItem = _merchantInventory.GetSlot(index).item
		_isFromMerchant = true
		_UpdateInfo())
		
	_playerInventoryContainer.slotPressed.connect(func(index:int):
		_merchantInventoryContainer.ClearSelection()
		_selectedItem = _playerInventory.GetSlot(index).item
		_isFromMerchant = false
		_UpdateInfo())
	
	_quantitySpinBox.value_changed.connect(func(_value:float):
		_UpdateInfo())
	
	for button in _presetsContainer.get_children():
		button.pressed.connect(_OnPresetButtonPressed.bind(button))
		_presetButtons.append(button)
	_UpdatePresetButtons()
	
	close_requested.connect(_OnClosePressed)
	window_input.connect(_OnWindowInput)
	
	# Desactivar tooltips en la ventana de comercio
	InventorySlot.SetTooltipsEnabled(false)
	
	# Habilitar el mouse filter del label para que pueda mostrar tooltips
	_infoLabel.mouse_filter = Control.MOUSE_FILTER_STOP

func _exit_tree() -> void:
	# Reactivar tooltips al cerrar la ventana
	InventorySlot.SetTooltipsEnabled(true)
	
func SetMerchantInventory(inventory:Inventory) -> void:
	_merchantInventoryContainer.SetInventory(inventory)
	_merchantInventory = inventory
	inventory.slotChanged.connect(func(_index:int, _stack:ItemStack):
		_UpdatePresetButtons())
	
func SetPlayerInventory(inventory:Inventory) -> void:
	_playerInventoryContainer.SetInventory(inventory)
	_playerInventory = inventory
	inventory.slotChanged.connect(func(_index:int, _stack:ItemStack):
		_UpdatePresetButtons())
 
func _UpdateInfo() -> void:
	_UpdateActionButton()
	_UpdatePresetButtons()
	if _selectedItem == null or _selectedItem.name.is_empty():
		_infoLabel.text = ""
		_itemIcon.texture = null
		_infoLabel.tooltip_text = ""
		return
	
	# Mostrar el icono del ítem
	_itemIcon.texture = _selectedItem.icon
	
	var quantity = _GetQuantity()
	var totalPrice = 0
	
	if _isFromMerchant:
		totalPrice = _CalculateSellPrice(_selectedItem.salePrice, quantity)
	else:
		totalPrice = _CalculateBuyPrice(_selectedItem.salePrice, quantity)
	
	# Truncar solo el nombre del ítem si es muy largo (más de 26 caracteres)
	var itemName = _selectedItem.name
	var displayName = itemName
	var maxNameLength = 26
	
	if itemName.length() > maxNameLength:
		displayName = itemName.substr(0, maxNameLength) + "..."
	
	var infoText = displayName
	infoText += "\n🪙 %d" % totalPrice
	
	if _selectedItem.IsWeapon():
		infoText += "\n⚔️ %d-%d" % [_selectedItem.minHit, _selectedItem.maxHit]
	elif _selectedItem.IsArmour():
		infoText += "\n🛡️ %d-%d" % [_selectedItem.minDef, _selectedItem.maxDef]
	
	_infoLabel.text = infoText
	
	# Tooltip solo con el nombre completo del ítem si fue truncado
	if itemName.length() > maxNameLength:
		_infoLabel.tooltip_text = itemName
	else:
		_infoLabel.tooltip_text = ""

func _UpdateActionButton() -> void:
	if _selectedItem == null or _selectedItem.name.is_empty():
		_actionButton.disabled = true
		_actionButton.text = "Comprar / Vender"
		return
	
	var totalPrice = 0
	if _isFromMerchant:
		totalPrice = _CalculateSellPrice(_selectedItem.salePrice, _GetQuantity())
		_actionButton.text = "Comprar (%d oro)" % totalPrice
	else:
		totalPrice = _CalculateBuyPrice(_selectedItem.salePrice, _GetQuantity())
		_actionButton.text = "Vender (%d oro)" % totalPrice
	_actionButton.disabled = false

func _CalculateSellPrice(objValue: float, objAmount: int) -> int:
	return int(objValue * objAmount + 0.5)
	
func _CalculateBuyPrice(objValue: float, objAmount: int) -> int:
	return int(objValue * objAmount)
	
func _GetQuantity() -> int:
	return int(_quantitySpinBox.value)

func _OnBuyButtonPressed() -> void:
	if _merchantInventoryContainer.GetSelectedSlot() == -1: return
	GameProtocol.WriteCommerceBuy(_merchantInventoryContainer.GetSelectedSlot() + 1, _GetQuantity());
	
func _OnSellButtonPressed() -> void:
	if _playerInventoryContainer.GetSelectedSlot() == -1: return
	GameProtocol.WriteCommerceSell(_playerInventoryContainer.GetSelectedSlot() + 1, _GetQuantity());
	
func _OnActionPressed() -> void:
	if _isFromMerchant:
		_OnBuyButtonPressed()
	else:
		_OnSellButtonPressed()

func _UpdatePresetButtons() -> void:
	var available = 0
	if _selectedItem != null and not _selectedItem.name.is_empty():
		var container = _merchantInventoryContainer if _isFromMerchant else _playerInventoryContainer
		var inventory = _merchantInventory if _isFromMerchant else _playerInventory
		var slotIndex = container.GetSelectedSlot()
		if slotIndex != -1:
			var stack = inventory.GetSlot(slotIndex)
			if stack:
				available = mini(stack.quantity, int(_quantitySpinBox.max_value))
	
	var buttonIndex = 0
	for i in _PRESET_STEPS.size():
		if _PRESET_STEPS[i] <= available:
			_SetPresetButton(buttonIndex, _PRESET_STEPS[i], _PRESET_LABELS[i])
			buttonIndex += 1
	# Último botón con la cantidad máxima disponible si no coincide con un preset fijo
	if available > 0 and (buttonIndex == 0 or _PRESET_STEPS[buttonIndex - 1] != available):
		_SetPresetButton(buttonIndex, available, str(available))
		buttonIndex += 1
	while buttonIndex < _presetButtons.size():
		_presetButtons[buttonIndex].visible = false
		buttonIndex += 1

func _SetPresetButton(index:int, quantity:int, label:String) -> void:
	var button = _presetButtons[index]
	button.text = label
	button.visible = true
	button.set_meta("quantity", quantity)

func _OnPresetButtonPressed(button:Button) -> void:
	_quantitySpinBox.value = int(button.get_meta("quantity"))
	
func _OnClosePressed() -> void:
	GameProtocol.WriteCommerceEnd()

# Manejar eventos de teclado para cerrar con Escape y bloquear otras teclas
func _OnWindowInput(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_OnClosePressed()
		# Consumir TODOS los eventos de teclado cuando la ventana está abierta
		# para evitar que se ejecuten acciones del juego (como equipar con E)
		set_input_as_handled()
