extends RefCounted
class_name GameContext

var playerInventory:Inventory = Inventory.new(Consts.MaxInventorySlots)
var merchantInventory:Inventory = Inventory.new(Consts.MaxInventorySlots)
var bankInventory:Inventory = Inventory.new(Consts.MaxBankInventorySlots) 
