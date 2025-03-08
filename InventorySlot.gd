extends PanelContainer
class_name InventorySlot

signal pressed

@onready var _icon: TextureRect = $MarginContainer/Icon
@onready var _quantity: Label = $Quantity
@onready var _equipped: Label = $Equipped
@onready var _selected: ColorRect = $Selected

var index:int = -1
  
func SetQuantity(quantity:int) -> void:
	_quantity.text = str(quantity) if quantity > 1 else ""
	
func SetIcon(texture:Texture2D) -> void:
	_icon.texture = texture
	
func SetEquipped(equipped:bool) -> void:
	_equipped.visible = equipped
	
func SetSelected(selected:bool) -> void:
	_selected.visible = selected

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed && event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			pressed.emit()
			
