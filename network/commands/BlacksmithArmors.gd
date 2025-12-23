extends RefCounted
class_name BlacksmithArmors

class Entry:
	var name:String
	var grh_index:int
	var lin_h:int
	var lin_p:int
	var lin_o:int
	var obj_index:int
	var upgrade:int

var entries:Array[Entry]

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader:StreamPeerBuffer) -> void:
	var count = reader.get_16()
	entries.resize(count)
	
	for i in count:
		var entry = Entry.new()
		entry.name = Utils.GetUnicodeString(reader)
		entry.grh_index = reader.get_32()
		entry.lin_h = reader.get_16()
		entry.lin_p = reader.get_16()
		entry.lin_o = reader.get_16()
		entry.obj_index = reader.get_16()
		entry.upgrade = reader.get_16()
		entries[i] = entry
