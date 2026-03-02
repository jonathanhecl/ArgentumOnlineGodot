extends TextureRect
class_name Minimap

signal click(mouse_position:Vector2)

const MAP_TILE_SIZE := 100
const DOT_SIZE := 5.0

# Offset de corrección para alinear el punto con la miniatura (en tiles)
# Positivo = mover a la derecha, Negativo = mover a la izquierda
const MINIMAP_OFFSET_X_TILES := -3.0  # El punto está 3 tiles desplazado a la derecha, corregimos hacia la izquierda
const MINIMAP_OFFSET_Y_TILES := 0.0

var _player_tile_x:int = 1
var _player_tile_y:int = 1
var _player_dot_position: Vector2 = Vector2.ZERO

var _texture_old: Texture2D = null
var _crossfade_alpha: float = 0.0
var _crossfade_tween: Tween = null
var _info_label: Label = null
var _current_map_id: int = 0

func _ready() -> void:
	_setup_info_label()
	update_player_position(0, 0)

func _setup_info_label() -> void:
	_info_label = Label.new()
	_info_label.name = "InfoLabel"
	_info_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_info_label.add_theme_font_size_override("font_size", 10)
	_info_label.add_theme_color_override("font_color", Color.WHITE)
	_info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_info_label.add_theme_constant_override("outline_size", 4)
	
	# Pequeño margen desde la esquina superior izquierda
	_info_label.offset_left = 4
	_info_label.offset_top = 4
	
	add_child(_info_label)

func _update_info_label_text() -> void:
	if _info_label:
		_info_label.text = "Mapa %d (%d, %d)" % [_current_map_id, _player_tile_x, _player_tile_y]

func _update_player_dot_position() -> void:
	# Aplicar offset de corrección a las coordenadas de tile
	var tx = clampi(_player_tile_x + int(MINIMAP_OFFSET_X_TILES), 1, MAP_TILE_SIZE)
	var ty = clampi(_player_tile_y + int(MINIMAP_OFFSET_Y_TILES), 1, MAP_TILE_SIZE)

	# Usar el tamaño del control para el mapeo (la textura se estira a este tamaño)
	# Tile (1,1) -> Pixel (0,0), Tile (100,100) -> Pixel (size.x, size.y)
	var px = (float(tx - 1) / float(MAP_TILE_SIZE - 1)) * size.x
	var py = (float(ty - 1) / float(MAP_TILE_SIZE - 1)) * size.y
	_player_dot_position = Vector2(px, py)
	
	# Debug
	print("[MINIMAP] Tile original: (%d, %d) | Con offset: (%d, %d) -> Pixel: (%.1f, %.1f)" % [_player_tile_x, _player_tile_y, tx, ty, px, py])

func load_thumbnail(map_id:int) -> void:
	_current_map_id = map_id
	_update_info_label_text()
	
	var path = "res://Assets/minimap_thumbnails/%d.bmp" % map_id
	var new_texture = load(path) if ResourceLoader.exists(path) else null
	
	if texture != new_texture and texture != null:
		_texture_old = texture
		texture = new_texture
		_crossfade_alpha = 1.0
		
		if _crossfade_tween and _crossfade_tween.is_valid():
			_crossfade_tween.kill()
			
		_crossfade_tween = create_tween()
		_crossfade_tween.tween_property(self, "_crossfade_alpha", 0.0, 0.5)
		_crossfade_tween.finished.connect(func(): queue_redraw())
		
		var step_tween = create_tween()
		step_tween.tween_method(func(_val): queue_redraw(), 0.0, 1.0, 0.5)
	else:
		texture = new_texture

func update_player_position(x:int, y:int) -> void:
	_player_tile_x = clampi(x, 1, MAP_TILE_SIZE)
	_player_tile_y = clampi(y, 1, MAP_TILE_SIZE)
	
	_update_player_dot_position()
	_update_info_label_text()
	queue_redraw()
	
func _draw() -> void:
	if _texture_old and _crossfade_alpha > 0.0:
		draw_texture_rect(_texture_old, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, _crossfade_alpha))

	var dot_offset = Vector2(DOT_SIZE * 0.5, DOT_SIZE * 0.5)
	var draw_pos = _player_dot_position - dot_offset
	draw_rect(Rect2(draw_pos, Vector2(DOT_SIZE, DOT_SIZE)), Color.RED, true)
	
	# Debug: mostrar dónde se dibujó el punto
	print("[MINIMAP DRAW] Dibujando punto en: (%.1f, %.1f) | size: %s" % [draw_pos.x, draw_pos.y, str(size)])


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			click.emit(event.position.ceil())
