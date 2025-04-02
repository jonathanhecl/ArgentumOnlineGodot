extends RefCounted
class_name TickIntervals

enum ActionTimers {
	MACRO_SPELLS,
	MACRO_WORK,
	ATTACK,
	ATTACK_WITH_BOW,
	SPELL,
	ATTACK_SPELL,
	SPELL_ATTACK ,
	WORK,
	USE_ITEM_WITH_U,
	USE_ITEM_WITH_DOUBLE_CLICK ,
	REQUEST_POSITION_UPDATE,
	TAME,
	STEAL
}

class TimerTick:
	var interval:int
	var elapsed_time:int
	
	func _init() -> void:
		interval = Time.get_ticks_msec()
		
	func get_tick() -> int:
		return elapsed_time + interval

var timers:Array[TimerTick]


func _init() -> void:
	timers.resize(ActionTimers.size())
	for i in timers.size():
		timers[i] = TimerTick.new()
	
	timers[ActionTimers.MACRO_SPELLS].interval = 2788
	timers[ActionTimers.MACRO_WORK].interval = 900
	timers[ActionTimers.ATTACK].interval = 1500
	timers[ActionTimers.ATTACK_WITH_BOW].interval = 1400
	timers[ActionTimers.SPELL].interval = 1400
	timers[ActionTimers.ATTACK_SPELL].interval = 1000
	timers[ActionTimers.SPELL_ATTACK].interval = 1000
	timers[ActionTimers.WORK].interval = 700
	timers[ActionTimers.USE_ITEM_WITH_U].interval = 450
	timers[ActionTimers.USE_ITEM_WITH_DOUBLE_CLICK].interval = 500
	timers[ActionTimers.REQUEST_POSITION_UPDATE].interval = 2000
	timers[ActionTimers.TAME].interval = 700
	timers[ActionTimers.STEAL].interval = 700

func _request_timer(index:int) -> bool:
	var tick = Time.get_ticks_msec()
	var timer = timers[index]
	
	if tick > timer.get_tick():
		timer.elapsed_time = tick
		return true
	return false

func request_pos_update() -> bool:
	return _request_timer(ActionTimers.REQUEST_POSITION_UPDATE) 


func request_macro_work() -> bool:
	return _request_timer(ActionTimers.MACRO_WORK)


func request_macro_spells() -> bool:
	return _request_timer(ActionTimers.MACRO_SPELLS)


func request_attack() -> bool:
	var tick = Time.get_ticks_msec()
	var attack_timer = timers[ActionTimers.ATTACK]
	var attack_with_bow = timers[ActionTimers.ATTACK_WITH_BOW]
	var spell_attack = timers[ActionTimers.SPELL_ATTACK]
	
	if tick > attack_with_bow.get_tick():
		if tick > spell_attack.get_tick():
			if tick > attack_timer.get_tick():
				attack_timer.elapsed_time = tick
				timers[ActionTimers.ATTACK_SPELL].elapsed_time = tick
				return true
	return false


func request_cast_spell() -> bool:
	var tick = Time.get_ticks_msec()
	var spell_timer = timers[ActionTimers.SPELL]
	var attack_with_bow = timers[ActionTimers.ATTACK_WITH_BOW]
	var attack_spell = timers[ActionTimers.ATTACK_SPELL]
	
	if tick > attack_with_bow.get_tick():
		if tick > attack_spell.get_tick():
			if tick > spell_timer.get_tick():
				spell_timer.elapsed_time = tick
				timers[ActionTimers.SPELL_ATTACK].elapsed_time = tick
				return true
	return false
	
	
func request_attack_with_bow() -> bool:
	return _request_timer(ActionTimers.ATTACK_WITH_BOW)


func request_use_item_with_u() -> bool:
	return _request_timer(ActionTimers.USE_ITEM_WITH_U)
	
	
func request_use_item_with_double_click() -> bool:
	return _request_timer(ActionTimers.USE_ITEM_WITH_DOUBLE_CLICK)
	
	
func request_tame() -> bool:
		return _request_timer(ActionTimers.TAME)
		
		
func request_steal() -> bool:
		return _request_timer(ActionTimers.STEAL)
