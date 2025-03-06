extends CanvasLayer
class_name GameInput

@export var _inventoryContainer:InventoryContainer
@export var _consoleRichTextLabel:RichTextLabel

var _gameContext:GameContext

func Init(gameContext:GameContext) -> void:
	_gameContext = gameContext
	_inventoryContainer.SetInventory(_gameContext.playerInventory)

func ShowConsoleMessage(message:String, fontData:FontData = FontData.new(Color.WHITE)) -> void:
	var bbcode = "[color=#%s]%s[/color]" % [fontData.color.to_html(), message]
	if fontData.italic:
		bbcode = "[i]%s[/i]" % bbcode;

	if fontData.bold:
		bbcode = "[b]%s[/b]" % bbcode;
	
	_consoleRichTextLabel.append_text(bbcode + "\n")
