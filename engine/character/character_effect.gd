extends AnimatedSprite2D
class_name CharacterEffect

var effect_id:int
var effect_loops:int

func _ready() -> void:
	animation_finished.connect(_on_animation_finished)


func play_effect(id:int, loops:int) -> void:
	effect_id = id
	effect_loops = loops
	
	if effect_id > 0:
		var fx_path = "res://Resources/Fxs/fx_%d.tres" % id
		if not ResourceLoader.exists(fx_path):
			push_warning("CharacterEffect: FX not found: %s" % fx_path)
			stop_effect()
			return
			
		sprite_frames = load(fx_path)
		if not sprite_frames or sprite_frames.get_frame_count("default") == 0:
			push_warning("CharacterEffect: Invalid FX resource: %s" % fx_path)
			stop_effect()
			return
		
		visible = true
		play("default")
		
		var texture = sprite_frames.get_frame_texture("default", 0)
		if texture:
			var height = texture.get_height()
			var offset_y = sprite_frames.get_meta("offset_y") if sprite_frames.has_meta("offset_y") else 0
			position.y = -height / 2.0 + offset_y
	else:
		stop_effect()
		
		
func stop_effect() -> void:
	stop()
	
	effect_id = 0
	effect_loops = 0
	visible = false
	

func _on_animation_finished() -> void:
	if effect_loops == Consts.InfiniteLoops:
		play("default")
	else:
		effect_loops = effect_loops - 1
		if effect_loops > 0:
			play("default")
		else:
			stop_effect()
		
