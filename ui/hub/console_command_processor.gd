extends Node
class_name ConsoleCommandProcessor

static var command_handler:Dictionary[String, Callable] = {
	"salir": quit,
	"est": request_stats,
	"invisible": invisible,
	"meditar": meditate,
	"desc": change_description,
	"boveda": open_vault,
	"depositar": deposit_gold,
	"retirar": withdraw_gold,
	"balance": request_balance,
	"online": request_online,
	"apostar": gamble,
	"resucitar": resucitate,
	"salirclan": guild_leave,
	"curar": heal,
	"comerciar": start_commerce
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
	
static func resucitate(args:ChatCommandArgs) -> void:
	if args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Ya estás vivo!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteResucitate()


static func change_description(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estas muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var description = " ".join(args.parameters) if args.parameters.size() else ""
	GameProtocol.change_description(description)


static func open_vault(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estás muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteBankStart()


static func deposit_gold(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estás muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /depositar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount_str = args.parameters[0]
	if !amount_str.is_valid_int():
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /depositar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount = amount_str.to_int()
	if amount <= 0:
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /depositar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteBankDepositGold(amount)


static func withdraw_gold(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estás muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /retirar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount_str = args.parameters[0]
	if !amount_str.is_valid_int():
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /retirar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount = amount_str.to_int()
	if amount <= 0:
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /retirar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteBankExtractGold(amount)


static func request_balance(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡Estás muerto!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteRequestAccountState()


static func request_online(args:ChatCommandArgs) -> void:
	GameProtocol.WriteOnline()


static func guild_leave(args:ChatCommandArgs) -> void:
	GameProtocol.WriteGuildLeave()


static func heal(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		GameProtocol.WriteResucitate()
		return
	
	GameProtocol.WriteHeal()


static func start_commerce(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if args.game_context.trading:
		args.hub_controller.ShowConsoleMessage("Ya estás comerciando", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteCommerceStart()


static func gamble(args:ChatCommandArgs) -> void:
	if !args.game_context.player_stats.is_alive():
		args.hub_controller.ShowConsoleMessage("¡¡Estás muerto!!", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	if args.parameters.size() == 0:
		args.hub_controller.ShowConsoleMessage("Faltan parámetros. Utilice /apostar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount_str = args.parameters[0]
	if !amount_str.is_valid_int():
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /apostar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	var amount = amount_str.to_int()
	if amount <= 0:
		args.hub_controller.ShowConsoleMessage("Cantidad incorrecta. Utilice /apostar CANTIDAD.", GameAssets.FontDataList[Enums.FontTypeNames.FontType_Info])
		return
	
	GameProtocol.WriteGamble(amount)
