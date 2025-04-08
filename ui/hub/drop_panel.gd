extends Window
@onready var spin_box: SpinBox = $SpinBox

var slot:int

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
