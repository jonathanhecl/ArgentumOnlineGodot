extends RefCounted
class_name Utils

static func GetFilesInDirectory(path:String) -> Array[String]:
	var files:Array[String] = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var fileName = dir.get_next()
		while fileName != "":
			if !dir.current_is_dir():
				files.append(fileName)
			fileName = dir.get_next()
		dir.list_dir_end()
	return files 

static func HeadingToVector(heading:int) -> Vector2:
	if(heading == Enums.Heading.East):
		return Vector2.RIGHT; 
	if(heading == Enums.Heading.North):
		return Vector2.UP; 
	if(heading == Enums.Heading.South):
		return Vector2.DOWN; 
	if(heading == Enums.Heading.West):
		return Vector2.LEFT;
	return Vector2.ZERO

static func VectorToHeading(vector:Vector2) -> int: 
	if(vector == Vector2.LEFT):
		return Enums.Heading.West
	if(vector == Vector2.RIGHT):
		return Enums.Heading.East
	if(vector == Vector2.UP):
		return Enums.Heading.North
	if(vector == Vector2.DOWN):
		return Enums.Heading.South
	
	if(vector == Vector2(-1, -1)):
		return Enums.Heading.West;
	if(vector == Vector2(-1, 1)):
		return Enums.Heading.West;
	if(vector == Vector2(1, -1)):
		return Enums.Heading.East;
	if(vector == Vector2(1, 1)):
		return Enums.Heading.East;

	return Enums.Heading.None; 
	
static func GetCameraBounds(camera:Camera2D) -> Rect2:
	return camera.get_canvas_transform().affine_inverse() * camera.get_viewport_rect()

static func Sgn(x:int) -> int:
	if x > 0:
		return 1
	if x < 0:
		return -1
	return 0
	
static func GetNickColor(nickColor:int, privileges:int) -> Color:
	if privileges == 0:
		if nickColor & Enums.NickColor.IeAtacable:
			return GameAssets.GetNickColor(49)
		else:
			if nickColor & Enums.NickColor.IeCriminal:
				return GameAssets.GetNickColor(50)
			else:
				return GameAssets.GetNickColor(49)
	else:
		return GameAssets.GetNickColor(privileges) 

static func GetUnicodeString(stream:StreamPeer) -> String:
	var size = stream.get_16()
	if size > 0:
		var data:PackedByteArray = stream.get_data(size)[1]
		return data.get_string_from_ascii() 
	return ""
	
static func Utf8ToLatin1(text:String) -> PackedByteArray:
	var latin1_bytes = PackedByteArray()
	
	for char in text:
		var code = char.unicode_at(0)
		
		# Latin-1 solo admite caracteres entre 0-255
		if code <= 255:
			latin1_bytes.append(code)
		else:
			# Reemplazar caracteres fuera de Latin-1 con '?'
			latin1_bytes.append(63)  # 63 = '?'

	return latin1_bytes
	
static func PutUnicodeString(stream:StreamPeer, text:String) -> void:
	if text.length() == 0:
		stream.put_16(0)
		return
	
	var data = Utf8ToLatin1(text)
	stream.put_16(data.size())
	stream.put_data(data)
