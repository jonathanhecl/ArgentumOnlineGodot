extends RefCounted
class_name ItemStack

var equipped:bool
var quantity:int
var item:Item

func _init(p_quantity:int = 0, p_equipped:bool = false, p_item:Item = null) -> void:
	quantity = p_quantity
	equipped = p_equipped
	item = p_item
