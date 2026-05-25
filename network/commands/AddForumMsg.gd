extends RefCounted
class_name AddForumMsg

var forumType: int
var title: String
var author: String
var message: String

func _init(reader: StreamPeerBuffer = null) -> void:
	if reader: Deserialize(reader)

func Deserialize(reader: StreamPeerBuffer) -> void:
	forumType = reader.get_u8()
	title = Utils.GetUnicodeString(reader)
	author = Utils.GetUnicodeString(reader)
	message = Utils.GetUnicodeString(reader)
