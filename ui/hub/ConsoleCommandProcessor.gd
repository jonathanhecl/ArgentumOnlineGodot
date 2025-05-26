extends Node
class_name ConsoleCommandProcessor

static var command_handler:Dictionary[String, Callable] = {
	"salir": quit,
	"est": request_stats,
	"invisible": invisible,
	"meditar": meditate
}

static func process(newText: String, hub_controller:HubController, game_context:GameContext) -> bool:
	var text = newText.strip_edges()
	
	if text.begins_with("/"):
		if text.length() == 1:
			return false
			
		var command_name = text.substr(1).split(" ")[0].to_lower()
		var args = ChatCommandArgs.new()
		args.parameters = text.substr(1).split(" ")
		args.parameters.remove_at(0)
		args.game_context = game_context
		args.hub_controller = hub_controller
		
		if command_handler.has(command_name): 
			command_handler[command_name].call(args)
			return true
	return false
	
		
static func quit(args:ChatCommandArgs) -> void:
	GameProtocol.WriteQuit()
	
	
static func request_stats(args:ChatCommandArgs) -> void:
	GameProtocol.WriteRequestStats()

	
static func invisible(args:ChatCommandArgs) -> void:
	GameProtocol.write_invisible()


static func meditate(args:ChatCommandArgs) -> void:
	if args.game_context.player_stats.mana == args.game_context.player_stats.max_mana:
		return
		
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estas muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteMeditate()
	
	
		
		
