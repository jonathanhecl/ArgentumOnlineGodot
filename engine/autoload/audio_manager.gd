extends Node

# Diccionario para rastrear sonidos que están reproduciéndose actualmente
var _playing_sounds: Dictionary = {}

func PlayAudio(waveId:int, from_server:bool = false, prevent_overlap:bool = false) -> void:
	# Si prevent_overlap está activo y el sonido ya se está reproduciendo, no hacer nada
	if prevent_overlap and _playing_sounds.has(waveId):
		print("[AudioManager] ⏭️ Sonido #%d ya se está reproduciendo, saltando..." % waveId)
		return
	
	# Log del sonido que se está reproduciendo
	if from_server:
		print("[AudioManager] 🔊 Reproduciendo sonido #%d (solicitado por SERVIDOR)" % waveId)
	else:
		print("[AudioManager] 🔊 Reproduciendo sonido #%d (local)" % waveId)
	
	if !ResourceLoader.exists("res://Assets/Sfx/%d.wav" % waveId):
		push_error("AudioManager: Audio resource not found: %d" % waveId)
		return
		
	var audioStreamPlayer = AudioStreamPlayer.new()
	add_child(audioStreamPlayer)
	
	audioStreamPlayer.stream = load("res://Assets/Sfx/%d.wav" % waveId)
	audioStreamPlayer.bus = "sfx"
	
	# Si prevent_overlap está activo, registrar el sonido
	if prevent_overlap:
		_playing_sounds[waveId] = audioStreamPlayer
		audioStreamPlayer.finished.connect(func():
			_playing_sounds.erase(waveId)
			audioStreamPlayer.queue_free()
		)
	else:
		audioStreamPlayer.finished.connect(audioStreamPlayer.queue_free)
	
	audioStreamPlayer.play()

func PlayAudioByName(sound_name: String) -> void:
	"""Reproduce un sonido por nombre de archivo (sin extensión)"""
	var path = "res://Assets/Sfx/%s.wav" % sound_name
	
	if not ResourceLoader.exists(path):
		push_error("AudioManager: Audio resource not found: %s" % path)
		return
	
	print("[AudioManager] 🔊 Reproduciendo sonido '%s'" % sound_name)
	
	var audioStreamPlayer = AudioStreamPlayer.new()
	add_child(audioStreamPlayer)
	
	audioStreamPlayer.stream = load(path)
	audioStreamPlayer.bus = "sfx"
	audioStreamPlayer.finished.connect(audioStreamPlayer.queue_free)
	audioStreamPlayer.play()
