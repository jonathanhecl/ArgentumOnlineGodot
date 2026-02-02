extends SceneTree

func _init() -> void:
	print("Starting Protocol Packet Simulator...")
	_run_simulation()
	quit()

func _run_simulation() -> void:
	var data = _build_attack_sequence()
	var stream = StreamPeerBuffer.new()
	stream.data_array = data

	ProtocolHandler.packet_debug_enabled = false
	while stream.get_position() < stream.get_size():
		ProtocolHandler._handle_one_packet(stream)

	if stream.get_position() == stream.get_size():
		print("SUCCESS: Packet stream consumed correctly (size=%d)." % stream.get_size())
	else:
		print("FAILURE: Stream position mismatch. pos=%d size=%d" % [stream.get_position(), stream.get_size()])

func _build_attack_sequence() -> PackedByteArray:
	var stream = StreamPeerBuffer.new()

	# PlayWave (40): wave, x, y
	stream.put_u8(Enums.ServerPacketID.PlayWave)
	stream.put_u8(103)
	stream.put_u8(21)
	stream.put_u8(19)

	# MultiMessage (102): NPCSwing (no extra args)
	stream.put_u8(Enums.ServerPacketID.MultiMessage)
	stream.put_u8(Enums.Messages.NPCSwing)

	# UpdateUserStats (46)
	stream.put_u8(Enums.ServerPacketID.UpdateUserStats)
	stream.put_16(232) # max_hp
	stream.put_16(232) # min_hp
	stream.put_16(1594) # max_mana
	stream.put_16(1594) # min_mana
	stream.put_16(210) # max_sta
	stream.put_16(210) # min_sta
	stream.put_32(21474780) # gold
	stream.put_u8(45) # level
	stream.put_32(2) # elu
	stream.put_32(14) # experience

	# CreateFX (45): charIndex, fx, fxLoops
	stream.put_u8(Enums.ServerPacketID.CreateFX)
	stream.put_16(232)
	stream.put_16(210)
	stream.put_16(220)

	# CreateDamage (112): x, y, damage, color
	stream.put_u8(Enums.ServerPacketID.CreateDamage)
	stream.put_u8(21)
	stream.put_u8(19)
	stream.put_32(45)
	stream.put_u8(2)

	# PosUpdate (21): x, y
	stream.put_u8(Enums.ServerPacketID.PosUpdate)
	stream.put_u8(19)
	stream.put_u8(21)

	return stream.data_array
