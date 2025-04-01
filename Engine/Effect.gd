extends AnimatedSprite2D
class_name Effect

var effect_id:int
var effect_loops:int

func play_effect(id:int, loops:int) -> void:
	effect_id = id
	effect_loops = loops
	
	if effect_id > 0:
		visible = true
		sprite_frames = load("res://Resources/Fxs/fx_%d.tres" % id)
		play("default")
		
		var height = sprite_frames.get_frame_texture("default", 0).get_height()
		position.y = -height / 2.0 + sprite_frames.get_meta("offset_y")
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
		
