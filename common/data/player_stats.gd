extends RefCounted
class_name PlayerStats

var hp:int
var max_hp:int

var mana:int
var max_mana:int

var sta:int
var max_sta:int

# Propiedades relacionadas con clanes
var guild_index:int = 0  # 0 = sin clan, >0 = índice del clan
var guild_name:String = ""
var guild_rank:int = 0  # Rango dentro del clan


func is_alive() -> bool:
	return hp > 0

# Verifica si el jugador está en un clan
func is_in_guild() -> bool:
	return guild_index > 0
