extends RefCounted
class_name Inventory

signal slotChanged(index:int, itemStack:ItemStack)

var _slots:Array[ItemStack]

func _init(size:int) -> void:
	_slots.resize(size)
	for i in size:
		_slots[i] = ItemStack.new(0, false, Item.new())
		
func GetSize() -> int:
	return _slots.size()
	
	
func GetSlot(index:int) -> ItemStack:
	if index < 0 or index >= _slots.size():
		push_warning("Inventory.GetSlot: Índice %d fuera de rango (tamaño: %d)" % [index, _slots.size()])
		return null
	return _slots[index]


func SetSlot(index:int, itemStack:ItemStack) -> void:
	if index < 0 or index >= _slots.size():
		push_warning("Inventory.SetSlot: Índice %d fuera de rango (tamaño: %d)" % [index, _slots.size()])
		return
	_slots[index] = itemStack
	slotChanged.emit(index, itemStack)
