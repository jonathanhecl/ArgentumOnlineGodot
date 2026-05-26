extends RefCounted
class_name InitCraftman

class CrafteoItem:
	var name: String
	var grh_index: int
	var obj_index: int
	var amount: int

class Entry:
	var name: String
	var grh_index: int
	var obj_index: int
	var items_crafteo: Array[CrafteoItem] = []

var craft_cost: int
var entries: Array[Entry] = []

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	craft_cost = reader.get_32()
	var count_objs = reader.get_16()
	entries.clear()
	
	for i in range(count_objs):
		var entry = Entry.new()
		entry.name = Utils.GetUnicodeString(reader)
		entry.grh_index = reader.get_32()
		entry.obj_index = reader.get_16()
		
		var count_crafteo = reader.get_u8()
		for j in range(count_crafteo):
			var craft_item = CrafteoItem.new()
			craft_item.name = Utils.GetUnicodeString(reader)
			craft_item.grh_index = reader.get_32()
			craft_item.obj_index = reader.get_16()
			craft_item.amount = reader.get_16()
			entry.items_crafteo.append(craft_item)
			
		entries.append(entry)
