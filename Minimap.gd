extends TextureRect
class_name Minimap

signal click(mouse_position:Vector2)

var _player_position_x:int
var _player_position_y:int

func _ready() -> void:
	update_player_position(0, 0)

func load_thumbnail(map_id:int) -> void:
	var path = "res://Assets/minimap_thumbnails/%d.bmp" % map_id
	texture = load(path) if ResourceLoader.exists(path)  else null 

func update_player_position(x:int, y:int) -> void:
	_player_position_x = clampi(x, 0, 100)
	_player_position_y = clampi(y, 0, 100)
	
	queue_redraw()
	
func _draw() -> void:
	draw_rect(Rect2(_player_position_x, _player_position_y, 5, 5), Color.RED, true)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			click.emit(event.position.ceil())
