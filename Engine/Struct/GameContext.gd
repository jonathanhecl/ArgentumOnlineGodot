extends RefCounted
class_name GameContext

var playerInventory:Inventory = Inventory.new(Consts.MaxInventorySlots)
var merchantInventory:Inventory = Inventory.new(Consts.MaxNpcInventorySlots)
var bankInventory:Inventory = Inventory.new(Consts.MaxBankInventorySlots) 

var player_stats:PlayerStats = PlayerStats.new()
var tick_intervals:TickIntervals = TickIntervals.new()

var traveling:bool
var trading:bool
var pause:bool
var mirandoForo:bool
var userParalizado:bool
var userDescansar:bool
var userMeditar:bool
var userNavegando:bool
var usingSkill:int

var pingTime:int
