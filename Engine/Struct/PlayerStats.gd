extends RefCounted
class_name PlayerStats

var hp:int
var max_hp:int

var mana:int
var max_mana:int

var sta:int
var max_sta:int


func is_alive() -> bool:
	return hp > 0
