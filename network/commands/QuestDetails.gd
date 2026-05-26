extends RefCounted
class_name QuestDetails

class QuestNPC:
	var qty: int
	var name: String
	var killed_qty: int = 0

class QuestOBJ:
	var qty: int
	var name: String

class RewardItem:
	var qty: int
	var name: String

var quest_started: bool
var mission_name: String
var details: String
var required_level: int
var npcs: Array[QuestNPC] = []
var objs: Array[QuestOBJ] = []
var gold: int
var exp: int
var rewards: Array[RewardItem] = []

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	quest_started = reader.get_u8() != 0
	mission_name = Utils.GetUnicodeString(reader)
	details = Utils.GetUnicodeString(reader)
	required_level = reader.get_u8()
	
	var npcs_count = reader.get_u8()
	npcs.clear()
	for i in range(npcs_count):
		var npc = QuestNPC.new()
		npc.qty = reader.get_16()
		npc.name = Utils.GetUnicodeString(reader)
		if quest_started:
			npc.killed_qty = reader.get_16()
		npcs.append(npc)
		
	var objs_count = reader.get_u8()
	objs.clear()
	for i in range(objs_count):
		var obj = QuestOBJ.new()
		obj.qty = reader.get_16()
		obj.name = Utils.GetUnicodeString(reader)
		objs.append(obj)
		
	gold = reader.get_32()
	exp = reader.get_32()
	
	var items_count = reader.get_u8()
	rewards.clear()
	for i in range(items_count):
		var reward = RewardItem.new()
		reward.qty = reader.get_16()
		reward.name = Utils.GetUnicodeString(reader)
		rewards.append(reward)
