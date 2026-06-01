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
	
	# Initialize GPUParticles2D with our forged spell_trail shader!
	_particles = GPUParticles2D.new()
	_particles.amount = 220
	_particles.lifetime = 1.3 # Vive lo suficiente para cubrir el vuelo (~0.25s) + perdurar ~1s tras el impacto
	_particles.local_coords = false # Coordenadas globales: las particulas quedan en el camino recorrido
	
	# Load the particle process shader (movement + azul->rojo color)
	var shader = load("res://shaders/spell_trail.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = shader
	_particles.process_material = mat
	
	# Distortion render shader: corrompe/refracta la imagen del fondo detras de la estela
	var distort_shader = load("res://shaders/spell_trail_distortion.gdshader")
	var distort_mat = ShaderMaterial.new()
	distort_mat.shader = distort_shader
	# Direccion del vuelo en screen-space (caster -> target) para la flecha de distorsion
	var flight_vec = target_char.global_position - caster_char.global_position
	var flight_dir = Vector2.RIGHT
	if flight_vec.length_squared() > 0.0001:
		flight_dir = flight_vec.normalized()
	distort_mat.set_shader_parameter("flight_dir", flight_dir)
	# Aumentado para que la flecha de distorsion sea visible
	distort_mat.set_shader_parameter("distortion_strength", 0.09)
	distort_mat.set_shader_parameter("tint_amount", 0.55)
	_particles.material = distort_mat
	
	# Create a soft, radial white glowing smoke puff texture
	var glow_grad = Gradient.new()
	glow_grad.set_color(0, Color(1, 1, 1, 1.0))
	glow_grad.set_color(1, Color(1, 1, 1, 0.0))
	var glow_tex = GradientTexture2D.new()
	glow_tex.gradient = glow_grad
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(0.5, 0.0)
	glow_tex.width = 16
	glow_tex.height = 16
	_particles.texture = glow_tex
	
	# Dynamic color from the spell's essence: start with the spell color, end in crimson fire
	var spell_start = _projectile_color.lightened(0.15)
	var spell_end = Color(1.0, 0.05, 0.05) # Crimson fire vapor
	mat.set_shader_parameter("start_color", spell_start)
	mat.set_shader_parameter("end_color", spell_end)
	mat.set_shader_parameter("color_intensity", 2.5)
	
	# Proportional thickness from spell sprite dimensions
	var tex_w = _spell_texture.get_width() if _spell_texture else 32.0
	var tex_h = _spell_texture.get_height() if _spell_texture else 32.0
	var base_scale = clampf(maxf(float(tex_w), float(tex_h)) / 40.0, 0.4, 1.8) * 0.7
	mat.set_shader_parameter("initial_scale", base_scale * 1.2)
	
	# Determine vertical offset: always set to character mid-height (Y = -32) so it never flies from the ground
	_fx_vertical_offset = Vector2(0, -32.0)
	
	# Initial positions: set global position BEFORE starting emission so global particles are spawned at the chest, not (0,0)
	_caster_ref = weakref(caster_char)
	_start_pos = caster_char.global_position + _fx_vertical_offset
	global_position = _start_pos
	
	# BackBufferCopy: captura la pantalla detras para que el shader de distorsion la pueda leer (requerido en GL Compatibility).
	# Se agrega ANTES que las particulas para que se dibuje primero en el orden del canvas.
	var bbc = BackBufferCopy.new()
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bbc)
	
	add_child(_particles)
	_particles.position = Vector2.ZERO
	_particles.emitting = true
	
	# Wave distortion: surco que avanza con el proyectil (como caña en el agua)
	# El Sprite2D se ancla en el lanzador y se estira hasta la posicion actual del proyectil
	_wave = Sprite2D.new()
	_wave.centered = false # El origen esta en el extremo izquierdo (inicio del surco)
	var wave_shader = load("res://shaders/spell_wave_distortion.gdshader")
	_wave_mat = ShaderMaterial.new()
	_wave_mat.shader = wave_shader
	_wave_mat.set_shader_parameter("amplitude", 0.007)
	_wave_mat.set_shader_parameter("frequency", 5.0)
	_wave_mat.set_shader_parameter("speed", 5.0)
	_wave_mat.set_shader_parameter("time_offset", randf() * 10.0)
	_wave_mat.set_shader_parameter("flight_angle", 0.0)
	_wave.material = _wave_mat
	_wave.z_index = 1
	_wave.visible = false # Se hace visible en el primer _process
	add_child(_wave)
	
	_target_ref = weakref(target_char)
	_on_arrival = on_arrival
	
	# Layering: set z_index = 0 (same as characters) and z_as_relative = true
	# to respect standard Y-sorting inside Layer3 so it travels behind tree trunks, stones, and walls!
	z_index = 0
	z_as_relative = true
	
	_is_launched = true

# Track particles reference
var _particles: GPUParticles2D = null
var _wave: Sprite2D = null
var _wave_mat: ShaderMaterial = null
var _wave_tex: GradientTexture2D = null
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
	
	# Actualizar el surco: anclar en el lanzador, estirar hasta la posicion actual
	if _wave and is_instance_valid(_wave) and _wave_mat:
		var flight_vec = global_position - _start_pos
		var length_px = flight_vec.length()
		if length_px > 2.0:
			var angle = flight_vec.angle()
			# Textura 1px de alto, length_px de ancho -> el shader la estira al surco completo
			if not _wave_tex or abs(_wave_tex.width - int(length_px)) > 4:
				_wave_tex = GradientTexture2D.new()
				var wg = Gradient.new()
				wg.set_color(0, Color(1, 1, 1, 1))
				wg.set_color(1, Color(1, 1, 1, 1))
				_wave_tex.gradient = wg
				_wave_tex.width = int(length_px)
				_wave_tex.height = 24 # Ancho del surco en pixeles
				_wave.texture = _wave_tex
			_wave.global_position = _start_pos
			_wave.rotation = angle
			_wave.offset = Vector2(0, -12) # Centrar verticalmente el surco
			_wave_mat.set_shader_parameter("flight_angle", angle)
			_wave.visible = true
		else:
			_wave.visible = false
	
	# Reached target
	if t >= 1.0:
		_on_arrival.call()
		
		# Stop processing and hide visual core immediately
		_is_launched = false
		_projectile_hidden = true
		queue_redraw()
		
		# Stop emitting new particles, but keep the node and simulation alive so active particles linger
		# Disipar el surco de distorsion suavemente durante 2 segundos
		if _wave and is_instance_valid(_wave) and _wave_mat:
			var tween = create_tween()
			tween.tween_method(func(v): _wave_mat.set_shader_parameter("dissipation", v), 0.0, 1.0, 2.0)
		if _particles and is_instance_valid(_particles):
			_particles.emitting = false
		# El nodo persiste 2 segundos para que el surco se disipe visiblemente
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(queue_free)

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
