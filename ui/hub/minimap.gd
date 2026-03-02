extends TextureRect
class_name Minimap

signal click(mouse_position:Vector2)

var _player_position_x:int
var _player_position_y:int

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
	_info_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_info_label.add_theme_font_size_override("font_size", 10)
	_info_label.add_theme_color_override("font_color", Color.WHITE)
	_info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_info_label.add_theme_constant_override("outline_size", 4)
	
	# Mover el label un poco hacia arriba para que no toque el borde exacto inferior
	_info_label.offset_bottom = -2
	
	add_child(_info_label)

func _update_info_label_text() -> void:
	if _info_label:
		_info_label.text = "Mapa %d (%d, %d)" % [_current_map_id, _player_position_x, _player_position_y]

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
	_player_position_x = clampi(x, 0, 100)
	_player_position_y = clampi(y, 0, 100)
	
	_update_info_label_text()
	queue_redraw()
	
func _draw() -> void:
	if _texture_old and _crossfade_alpha > 0.0:
		draw_texture_rect(_texture_old, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, _crossfade_alpha))

	draw_rect(Rect2(_player_position_x, _player_position_y, 5, 5), Color.RED, true)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			click.emit(event.position.ceil())
