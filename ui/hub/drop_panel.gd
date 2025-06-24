extends Window
@onready var spin_box: SpinBox = $SpinBox

var slot:int

func _ready():
	# Solo hacer focus una vez, sin señales
	call_deferred("_do_focus")

func _do_focus():
	if spin_box and is_node_ready():
		var line_edit = spin_box.get_line_edit()
		if line_edit:
			line_edit.grab_focus()
			line_edit.select_all()

func get_quantity() -> int:
	return int(spin_box.value)

func drop(quantity:int) -> void:
	if quantity > 0:
		GameProtocol.WriteDrop(slot, quantity) 
	queue_free()

func _on_btn_drop_pressed() -> void:
	drop(get_quantity())

func _on_btn_drop_aall_pressed() -> void:
	drop(Consts.MaxInventoryObjs)
