extends SceneTree

func _init():
	print("Starting String Parsing Tests...")
	test_string_parsing()
	quit()

# Copied from Utils.gd for isolation testing
func GetUnicodeString(stream:StreamPeer) -> String:
	var size = stream.get_16()
	if size > 0:
		var data:PackedByteArray = stream.get_data(size)[1]
		# CHANGED: get_string_from_multibyte_char -> get_string_from_ascii
		return data.get_string_from_ascii()
	return ""

func PutUnicodeString(stream:StreamPeer, text:String) -> void:
	if text.length() == 0:
		stream.put_16(0)
		return
	
	var data = Utf8ToLatin1(text)
	stream.put_16(data.size())
	stream.put_data(data)

func Utf8ToLatin1(text:String) -> PackedByteArray:
	var latin1_bytes = PackedByteArray()
	
	for c in text:
		var code = c.unicode_at(0)
		
		# Latin-1 solo admite caracteres entre 0-255
		if code <= 255:
			latin1_bytes.append(code)
		else:
			# Reemplazar caracteres fuera de Latin-1 con '?'
			latin1_bytes.append(63)  # 63 = '?'

	return latin1_bytes

func test_string_parsing():
	var test_str = "Hola Mundo! ñáéíóú"
	print("Original String: ", test_str)
	
	# Test Encoding (PutUnicodeString logic)
	var stream = StreamPeerBuffer.new()
	PutUnicodeString(stream, test_str)
	
	var data = stream.data_array
	print("Encoded Bytes: ", data)
	
	# Reset cursor to read back
	stream.seek(0)
	
	# Test Decoding (GetUnicodeString logic)
	var decoded_str = GetUnicodeString(stream)
	print("Decoded String: ", decoded_str)
	
	if test_str == decoded_str:
		print("SUCCESS: Strings match!")
	else:
		print("FAILURE: Strings do not match!")
		print("Expected: ", test_str)
		print("Got: ", decoded_str)

	# Test with manual byte construction for VB6 simulation (Latin-1)
	# "ñ" is 241 (0xF1) in Latin-1
	var stream_vb6 = StreamPeerBuffer.new()
	stream_vb6.put_16(1) # Length 1
	stream_vb6.put_u8(0xF1) # 'ñ' in Latin-1
	stream_vb6.seek(0)
	
	var decoded_vb6 = GetUnicodeString(stream_vb6)
	print("VB6 Simulation 'ñ' (0xF1): ", decoded_vb6)
	
	if decoded_vb6 == "ñ":
		print("SUCCESS: VB6 'ñ' decoded correctly")
	else:
		print("FAILURE: VB6 'ñ' decoded incorrectly. Got: ", decoded_vb6)
