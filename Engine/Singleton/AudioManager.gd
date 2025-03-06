extends Node

func PlayAudio(waveId:int) -> void:
	if !ResourceLoader.exists("res://Assets/Sfx/%d.wav" % waveId):
		push_error("AudioManager: Audio resource not found: %d" % waveId)
		return
		
	var audioStreamPlayer = AudioStreamPlayer.new()
	add_child(audioStreamPlayer)
	
	audioStreamPlayer.stream = load("res://Assets/Sfx/%d.wav" % waveId)
	audioStreamPlayer.bus = "sfx"
	audioStreamPlayer.finished.connect(audioStreamPlayer.queue_free)
	audioStreamPlayer.play()
