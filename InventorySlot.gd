extends PanelContainer
class_name InventorySlot

signal pressed
   
var index:int = -1
  
func SetQuantity(quantity:int) -> void:
	%Quantity.text = str(quantity) if quantity > 1 else ""
	
func SetIcon(texture:Texture2D) -> void:
	$Icon.texture = texture
	
func SetEquipped(equipped:bool) -> void:
	%Equipped.visible = equipped
	
func SetSelected(selected:bool) -> void:
	%Selected.visible = selected

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed && event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			pressed.emit()
			
