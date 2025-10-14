extends PanelContainer
class_name InventorySlot

signal pressed
signal drag_started(from_index: int)
   
var index:int = -1
var _item_icon: Texture2D = null
var _item_quantity: int = 0
  
func SetQuantity(quantity:int) -> void:
	_item_quantity = quantity
	%Quantity.text = str(quantity) if quantity > 1 else ""
	
func SetIcon(texture:Texture2D) -> void:
	_item_icon = texture
	$Icon.texture = texture
	
func SetEquipped(equipped:bool) -> void:
	%Equipped.visible = equipped
	
func SetSelected(selected:bool) -> void:
	%Selected.visible = selected

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Click izquierdo para selección
		if event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
		# Click derecho para drag and drop
		elif event.pressed && event.button_index == MOUSE_BUTTON_RIGHT:
			if _item_icon != null:
				drag_started.emit(index)
				var preview = _create_preview()
				force_drag({"from_index": index}, preview)

func _create_preview() -> Control:
	# Crear un contenedor para centrar el icono
	var container = Control.new()
	container.custom_minimum_size = Vector2(32, 32)
	
	var preview = TextureRect.new()
	preview.texture = _item_icon
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.modulate = Color(1, 1, 1, 0.7)
	# Centrar el preview en el contenedor
	preview.position = Vector2(-16, -16)  # Offset para centrar (mitad del tamaño)
	container.add_child(preview)
	
	if _item_quantity > 1:
		var label = Label.new()
		label.text = str(_item_quantity)
		label.position = Vector2(-14, 0)  # Ajustar posición relativa al centro
		container.add_child(label)
	
	return container

# Aceptar drops para evitar el cursor de prohibido
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_DICTIONARY:
		if data.has("from_index"):
			return true  # Siempre aceptar para evitar el cursor prohibido
	return false

func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	# No hacer nada aquí, el movimiento se maneja en inventory_container
	pass

			
