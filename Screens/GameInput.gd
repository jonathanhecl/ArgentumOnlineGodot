extends CanvasLayer
class_name GameInput

@export var _inventoryContainer:InventoryContainer

var _gameContext:GameContext

func Init(gameContext:GameContext) -> void:
	_gameContext = gameContext
	_inventoryContainer.SetInventory(_gameContext.playerInventory)
