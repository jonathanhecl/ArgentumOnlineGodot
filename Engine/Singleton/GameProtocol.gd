extends Node
class_name GameProtocol

static var _writer:StreamPeerBuffer = StreamPeerBuffer.new()

static func Flush() -> PackedByteArray:
	var data = _writer.data_array
	_writer.clear() 
	return data

static func WriteLoginExistingCharacter(username:String, password:String) -> void:
	_writer.put_u8(Enums.ClientPacketID.LoginExistingChar)
	Utils.PutUnicodeString(_writer, username)
	Utils.PutUnicodeString(_writer, password)
	_writer.put_u8(0)
	_writer.put_u8(13)
	_writer.put_u8(0)
