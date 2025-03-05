extends RefCounted
class_name PlayMidi

var midiId:int
var loops:int 

func _init(reader:StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader:StreamPeerBuffer) -> void:
	midiId = reader.get_16()
	loops = reader.get_16() 
