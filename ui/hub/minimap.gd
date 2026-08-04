extends TextureRect
class_name Minimap

signal click(mouse_position:Vector2)
signal player_tile_changed(new_tile: Vector2i)

const MAP_TILE_SIZE := 100
const DOT_SIZE := 5.0
const DEFAULT_ALPHA := 0.3
const HOVER_ALPHA := 1.0
const ALPHA_FADE_DURATION := 0.2

var _player_tile_x:int = 1
var _player_tile_y:int = 1
var _player_dot_position: Vector2 = Vector2.ZERO

var _texture_old: Texture2D = null
var _crossfade_alpha: float = 0.0
var _crossfade_tween: Tween = null
var _alpha_tween: Tween = null
var _info_label: Label = null
var _current_map_id: int = 0

func _ready() -> void:
	_setup_info_label()
	update_player_position(0, 0)
	modulate.a = DEFAULT_ALPHA
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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
	var tx = clampi(_player_tile_x, 1, MAP_TILE_SIZE)
	var ty = clampi(_player_tile_y, 1, MAP_TILE_SIZE)

	# Usar el tamaño del control para el mapeo (la textura se estira a este tamaño)
	# Tile (1,1) -> Pixel (0,0), Tile (100,100) -> Pixel (size.x, size.y)
	var px = (float(tx - 1) / float(MAP_TILE_SIZE - 1)) * size.x
	var py = (float(ty - 1) / float(MAP_TILE_SIZE - 1)) * size.y
	_player_dot_position = Vector2(px, py)

func load_thumbnail(map_id:int) -> void:
	_current_map_id = map_id
	_update_info_label_text()
	
	var path = "res://Assets/minimap_thumbnails/%d.bmp" % map_id
	var source_texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
	var new_texture: Texture2D = _crop_thumbnail(source_texture)
	
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

func _crop_thumbnail(source: Texture2D) -> Texture2D:
	if source == null:
		return null
	var source_size := Vector2i(source.get_size())
	if source_size.x <= MAP_TILE_SIZE or source_size.y <= MAP_TILE_SIZE:
		return source
	var crop_size := Vector2i(MAP_TILE_SIZE, MAP_TILE_SIZE)
	var region := Rect2i((source_size - crop_size) / 2, crop_size)
	var cropped := AtlasTexture.new()
	cropped.atlas = source
	cropped.region = region
	return cropped

func update_player_position(x:int, y:int) -> void:
	var new_tile := Vector2i(clampi(x, 1, MAP_TILE_SIZE), clampi(y, 1, MAP_TILE_SIZE))
	if new_tile == Vector2i(_player_tile_x, _player_tile_y):
		return
	
	_player_tile_x = new_tile.x
	_player_tile_y = new_tile.y
	
	_update_player_dot_position()
	_update_info_label_text()
	queue_redraw()
	player_tile_changed.emit(new_tile)

func get_player_tile() -> Vector2i:
	return Vector2i(_player_tile_x, _player_tile_y)
	
func _draw() -> void:
	if _texture_old and _crossfade_alpha > 0.0:
		draw_texture_rect(_texture_old, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, _crossfade_alpha))

	var dot_offset = Vector2(DOT_SIZE * 0.5, DOT_SIZE * 0.5)
	var draw_pos = _player_dot_position - dot_offset
	draw_rect(Rect2(draw_pos, Vector2(DOT_SIZE, DOT_SIZE)), Color.RED, true)


func _set_alpha_smoothly(target_alpha: float) -> void:
	if _alpha_tween and _alpha_tween.is_valid():
		_alpha_tween.kill()
	_alpha_tween = create_tween()
	_alpha_tween.tween_property(self, "modulate:a", target_alpha, ALPHA_FADE_DURATION)

func _on_mouse_entered() -> void:
	_set_alpha_smoothly(HOVER_ALPHA)

func _on_mouse_exited() -> void:
	_set_alpha_smoothly(DEFAULT_ALPHA)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.pressed and button_event.button_index == MOUSE_BUTTON_LEFT:
			click.emit(button_event.position.ceil())
