extends Sprite2D
class_name SpellProjectile

# Tracking variables for homing movement
var _target_ref: WeakRef
var _caster_ref: WeakRef
var _on_arrival: Callable
var _start_pos: Vector2
var _fx_vertical_offset: Vector2
var _duration: float = 0.25 # Snappy, fast and highly satisfying speed (0.25 seconds)
var _elapsed_time: float = 0.0
var _is_launched: bool = false
var _projectile_hidden: bool = false

# The color of the magic projectile (computed dynamically based on spell FX texture)
var _projectile_color: Color = Color.WHITE

# Private reference to draw the spell texture at the custom scaled size of the sphere
var _spell_texture: Texture2D = null

func _ready() -> void:
	# Use nearest-neighbor texture filtering to preserve high-fidelity pixel art
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	if _projectile_hidden:
		return
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

func launch(fx_id: int, caster_char, target_char, on_arrival: Callable) -> void:
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
	
	# Aclarar el color promedio por exactamente un 25% tendiendo hacia blanco (pastel brillante mágico)
	raw_color = raw_color.lerp(Color.WHITE, 0.25)
	_projectile_color = raw_color
	
	queue_redraw() # Force Godot to redraw our custom _draw callback with the new color!
	
	# Initialize CPUParticles2D for 100% compatibility with GL Compatibility renderer
	_particles = CPUParticles2D.new()
	_particles.amount = 220
	_particles.lifetime = 2.2
	_particles.local_coords = false
	
	# Create a soft, radial white glowing smoke puff texture dynamically!
	var glow_grad = Gradient.new()
	glow_grad.set_color(0, Color(1, 1, 1, 1.0)) # Solid white center
	glow_grad.set_color(1, Color(1, 1, 1, 0.0)) # Fades to transparent at the edge
	
	var glow_tex = GradientTexture2D.new()
	glow_tex.gradient = glow_grad
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(0.5, 0.0)
	glow_tex.width = 16
	glow_tex.height = 16
	_particles.texture = glow_tex
	
	# Configure physical dispersion: slow upward evaporation regardless of shot angle
	_particles.direction = Vector2.ZERO
	_particles.spread = 180.0
	_particles.gravity = Vector2(0, -14.0)   # Ultra-slow upward drift to linger near ground
	_particles.initial_velocity_min = 2.5
	_particles.initial_velocity_max = 8.5    # Soft initial burst to keep the trail dense and tight
	
	# Damping: Slows down expansion as the smoke ages (essential for real smoke feel!)
	_particles.damping_min = 1.0
	_particles.damping_max = 2.5
	
	# Rotación angular (giro) para mayor realismo de nubes de humo
	_particles.angle_min = 0.0
	_particles.angle_max = 360.0             # Cada partícula nace con rotación aleatoria
	_particles.angular_velocity_min = -50.0
	_particles.angular_velocity_max = 50.0   # Las partículas giran lentamente al viajar
	
	# Color: Tint particles with the brightened average color of the spell!
	_particles.color = _projectile_color
	
	# Color Ramp: Smoothly fade out over lifetime (Opacity goes 85% -> 60% -> 0% to linger and fade slowly)
	var ramp_gradient = Gradient.new()
	ramp_gradient.set_color(0, Color(1, 1, 1, 0.85)) # Birth: dense rich smoke
	ramp_gradient.add_point(0.45, Color(1, 1, 1, 0.60)) # Lingers on ground for 45% of life
	ramp_gradient.set_color(1, Color(1, 1, 1, 0.0))  # Slowly fades to transparent in the second half
	_particles.color_ramp = ramp_gradient
	
	# Scale Curve: Realistic billowing smoke curve (Starts compact, expands/billows, then dissolves)
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.35)) # Starts tight
	curve.add_point(Vector2(0.22, 1.0))  # Billows/Expands to maximum volume quickly
	curve.add_point(Vector2(1.0, 0.0))   # Dissolves into thin air
	_particles.scale_amount_curve = curve
	
	# Proportional Thickness: Scale base thickness dynamically based on spell sprite dimensions (shrunk 30% for a highly refined trail)
	var tex_w = _spell_texture.get_width() if _spell_texture else 32.0
	var tex_h = _spell_texture.get_height() if _spell_texture else 32.0
	var base_scale = clampf(maxf(float(tex_w), float(tex_h)) / 40.0, 0.4, 1.8) * 0.7
	_particles.scale_amount_min = base_scale * 0.9
	_particles.scale_amount_max = base_scale * 1.55
	
	# Determine vertical offset: always set to character mid-height (Y = -32) so it never flies from the ground
	_fx_vertical_offset = Vector2(0, -32.0)
	
	# Initial positions: set global position BEFORE starting emission so global particles are spawned at the chest, not (0,0)
	_caster_ref = weakref(caster_char)
	_start_pos = caster_char.global_position + _fx_vertical_offset
	global_position = _start_pos
	
	add_child(_particles)
	_particles.position = Vector2.ZERO
	_particles.emitting = true
	
	_target_ref = weakref(target_char)
	_on_arrival = on_arrival
	
	# Layering: set z_index = 0 (same as characters) and z_as_relative = true
	# to respect standard Y-sorting inside Layer3 so it travels behind tree trunks, stones, and walls!
	z_index = 0
	z_as_relative = true
	
	_is_launched = true

# Track particles reference
var _particles: CPUParticles2D = null
var _is_first_frame: bool = true

func is_flying() -> bool:
	return _is_launched

func get_caster_ref() -> WeakRef:
	return _caster_ref

func get_target_ref() -> WeakRef:
	return _target_ref

func _process(delta: float) -> void:
	if not _is_launched:
		return
		
	if _is_first_frame:
		_is_first_frame = false
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
		
		# Stop processing and hide visual core immediately
		_is_launched = false
		_projectile_hidden = true
		queue_redraw()
		
		# Stop emitting new particles, but keep the node and simulation alive so active particles linger
		if _particles and is_instance_valid(_particles):
			_particles.emitting = false
			var lifetime = _particles.lifetime
			var timer = get_tree().create_timer(lifetime + 0.2)
			timer.timeout.connect(queue_free)
		else:
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
