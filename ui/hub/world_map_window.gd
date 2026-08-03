extends Window
class_name WorldMapWindow

@onready var _view: WorldMapView = $View

func _ready() -> void:
	exclusive = true
	close_requested.connect(_on_close_requested)
	_view.close_requested.connect(_on_close_requested)

func show_map(current_map_id: int, player_tile: Vector2i) -> void:
	_view.show_map(current_map_id, player_tile)
	if current_map_id > 0:
		title = "Mapa del Mundo — Mapa %d" % current_map_id
	else:
		title = "Mapa del Mundo"

func refresh(current_map_id: int, player_tile: Vector2i) -> void:
	var old_map_id := _view.get_current_map_id()
	_view.refresh(current_map_id, player_tile)
	if current_map_id > 0 and current_map_id != old_map_id:
		title = "Mapa del Mundo — Mapa %d" % current_map_id

func _on_close_requested() -> void:
	hide()
