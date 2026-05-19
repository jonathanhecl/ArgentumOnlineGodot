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

# The color of the magic projectile (computed dynamically based on spell FX texture)
var _projectile_color: Color = Color.WHITE

# Private reference to draw the spell texture at the custom scaled size of the sphere
var _spell_texture: Texture2D = null

func _ready() -> void:
	# Use nearest-neighbor texture filtering to preserve high-fidelity pixel art
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	# Draw a glowing magic orb matching the spell's custom average color (+20% brightness)
	# Scaled down 30% as requested (0.7x scale) for a beautiful, compact look
	var glow_color = _projectile_color
	glow_color.a = 0.35 # Semi-transparent aura
	
	# 1. Outer glow aura (smooth) - 4.5 pixels radius (down from 6.5)
	draw_circle(Vector2.ZERO, 4.5, glow_color)
	
	# 2. Solid inner core - 2.5 pixels radius (down from 3.5)
	draw_circle(Vector2.ZERO, 2.5, _projectile_color)
	
	# 3. Draw the spell's animation frame scaled down exactly to the size of the sphere core (8.5 pixels wide/high)
	if _spell_texture:
		var target_size = Vector2(8.5, 8.5)
		var dest_rect = Rect2(-target_size / 2.0, target_size)
		draw_texture_rect(_spell_texture, dest_rect, false)

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
		
	# Store spell texture for custom drawing in _draw() instead of giant Sprite2D default texture
	_spell_texture = first_frame_tex
	texture = null # Skip default unscaled Sprite2D texture drawing
	
	# Compute average color of the spell texture dynamically for the flying magic orb!
	var raw_color = _get_average_color(first_frame_tex)
	
	# Increase the brightness by exactly 20% to make it highly vibrant
	raw_color.r = clampf(raw_color.r * 1.20, 0.0, 1.0)
	raw_color.g = clampf(raw_color.g * 1.20, 0.0, 1.0)
	raw_color.b = clampf(raw_color.b * 1.20, 0.0, 1.0)
	_projectile_color = raw_color
	
	queue_redraw() # Force Godot to redraw our custom _draw callback with the new color!
	
	# Determine vertical offset from FX metadata
	var height = first_frame_tex.get_height()
	var offset_y = sprite_frames.get_meta("offset_y") if sprite_frames.has_meta("offset_y") else 0
	_fx_vertical_offset = Vector2(0, -height / 2.0 + offset_y)
	
	# Initial positions
	_start_pos = start_pos + _fx_vertical_offset
	global_position = _start_pos
	
	_target_ref = weakref(target_char)
	_on_arrival = on_arrival
	
	# Layering: set z_index = 0 (same as characters) and z_as_relative = true
	# to respect standard Y-sorting inside Layer3 so it travels behind tree trunks, stones, and walls!
	z_index = 0
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

# Computes the average color of all non-transparent pixels in the given texture
func _get_average_color(tex: Texture2D) -> Color:
	if not tex:
		return Color.WHITE
		
	var img = tex.get_image()
	if not img:
		return Color.WHITE
		
	var total_color = Color(0, 0, 0, 0)
	var pixel_count = 0
	var w = img.get_width()
	var h = img.get_height()
	
	# Use step based on size to ensure it is always blazing fast (high performance)
	var step = 1
	if w > 64 or h > 64:
		step = 2
	if w > 128 or h > 128:
		step = 4
		
	for x in range(0, w, step):
		for y in range(0, h, step):
			var color = img.get_pixel(x, y)
			# Average only visible pixels, ignoring transparent ones and absolute black chroma key transparency
			if color.a > 0.15 and not (color.r < 0.08 and color.g < 0.08 and color.b < 0.08):
				total_color.r += color.r
				total_color.g += color.g
				total_color.b += color.b
				pixel_count += 1
				
	if pixel_count > 0:
		return Color(total_color.r / pixel_count, total_color.g / pixel_count, total_color.b / pixel_count, 1.0)
		
	return Color.WHITE
