extends RefCounted
class_name RecordList

var records: Array[String] = []

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: deserialize(reader)

func deserialize(reader: StreamPeerBuffer) -> void:
	var num_records = reader.get_u8()
	records.clear()
	for i in range(num_records):
		records.append(Utils.GetUnicodeString(reader))
