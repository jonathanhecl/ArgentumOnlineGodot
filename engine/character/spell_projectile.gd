extends Sprite2D
class_name SpellProjectile

# Tracking variables for homing movement
var _target_ref: WeakRef
var _on_arrival: Callable
var _start_pos: Vector2
var _fx_vertical_offset: Vector2
var _duration: float = 0.45 # Snappy, fast and highly satisfying speed (0.45 seconds)
var _elapsed_time: float = 0.0
var _is_launched: bool = false

func _ready() -> void:
	# Use nearest-neighbor texture filtering to preserve high-fidelity pixel art
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	# Draw a highly visible white circle of radius 4.0 at the center (glowing magic orb)
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)

func launch(fx_id: int, start_pos: Vector2, target_char, on_arrival: Callable) -> void:
	var fx_path = "res://Resources/Fxs/fx_%d.tres" % fx_id
	if not ResourceLoader.exists(fx_path):
		on_arrival.call()
		queue_free()
		return
		
	var sprite_frames = load(fx_path) as SpriteFrames
	if not sprite_frames or sprite_frames.get_frame_count("default") == 0:
		on_arrival.call()
		queue_free()
		return
		
	# Use frame index 1 (frame 2) if it exists, as frame 0 is often transparent or empty in AO spells.
	var frame_index = 0
	if sprite_frames.get_frame_count("default") > 1:
		frame_index = 1
		
	var first_frame_tex = sprite_frames.get_frame_texture("default", frame_index)
	if not first_frame_tex:
		on_arrival.call()
		queue_free()
		return
		
	texture = first_frame_tex
	
	# Determine vertical offset from FX metadata
	var height = first_frame_tex.get_height()
	var offset_y = sprite_frames.get_meta("offset_y") if sprite_frames.has_meta("offset_y") else 0
	_fx_vertical_offset = Vector2(0, -height / 2.0 + offset_y)
	
	# Initial positions
	_start_pos = start_pos + _fx_vertical_offset
	global_position = _start_pos
	
	_target_ref = weakref(target_char)
	_on_arrival = on_arrival
	
	# Layering: set z_index = 1 and z_as_relative = true to draw on top of background map layer tiles
	# making it perfectly and beautifully visible in front of the map ground
	z_index = 1
	z_as_relative = true
	
	_is_launched = true

func _process(delta: float) -> void:
	if not _is_launched:
		return
		
	_elapsed_time += delta
	var t = clampf(_elapsed_time / _duration, 0.0, 1.0)
	
	# Get target's current position dynamically (homing behavior)
	var target_char = _target_ref.get_ref()
	var current_end_pos = _start_pos
	if target_char and is_instance_valid(target_char) and target_char.is_inside_tree():
		current_end_pos = target_char.global_position + _fx_vertical_offset
	else:
		# If target disappeared, keep flying to the last known position
		current_end_pos = global_position
		
	# Smoothly interpolate position dynamically in real-time
	global_position = _start_pos.lerp(current_end_pos, t)
	
	# Reached target
	if t >= 1.0:
		_on_arrival.call()
		queue_free()
