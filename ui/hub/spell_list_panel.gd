extends TextureRect
class_name SpellListPanel

@onready var _item_list: ItemList = $ItemList

func _ready() -> void:
	for i in Consts.MaxUserHechizos:
		_item_list.add_item("(Nada)")
	
	# Conectar la selección de hechizos al sistema de macro
	_item_list.item_selected.connect(_on_spell_selected)


func get_selected_slot() -> int:
	var selected_item = _item_list.get_selected_items()
	if selected_item.is_empty():
		return -1
	return selected_item[0]


func set_slot_text(slot:int, text:String) -> void:
	_item_list.set_item_text(slot, text)
	if text != "" and text != "(Nada)" and text != "(None)":
		_item_list.set_item_icon(slot, _get_placeholder_icon())
	else:
		_item_list.set_item_icon(slot, null)


func _on_spell_selected(index: int) -> void:
	# Notificar al sistema de macro qué hechizo está seleccionado
	SpellMacroSystem.set_selected_spell_index(index)
	SpellMacroSystem.set_spell_list(self)
	print("[SpellListPanel] Hechizo seleccionado: ", index, " - ", _item_list.get_item_text(index))


func get_selected_spell_text() -> String:
	var slot = get_selected_slot()
	if slot == -1:
		return ""
	return _item_list.get_item_text(slot)


func _on_btn_cast_pressed() -> void:
	var slot = get_selected_slot() 
	if slot == -1 || _item_list.get_item_text(slot) == "(Nada)": 
		return 
		
	ProtocolWriteToServer.WriteCastSpell(slot + 1)
	ProtocolWriteToServer.WriteWork(Enums.Skill.Magia)


func _on_btn_info_pressed() -> void:
	var slot = get_selected_slot()
	if slot == -1 or _item_list.get_item_text(slot) == "(Nada)":
		return

	# No-op: el cliente actual no implementa solicitud de info de hechizo.
	return


func _on_btn_move_up_pressed() -> void:
	if get_selected_slot() <= 0: return
	_item_list.move_item(get_selected_slot(), get_selected_slot() - 1)
	_item_list.select(get_selected_slot())
	ProtocolWriteToServer.WriteMoveSpell(false, get_selected_slot() + 1) 


func _on_btn_move_down_pressed() -> void:
	if get_selected_slot() != -1 && get_selected_slot() + 1 ==  Consts.MaxUserHechizos: return
	_item_list.move_item(get_selected_slot(), get_selected_slot() + 1)
	_item_list.select(get_selected_slot())
	ProtocolWriteToServer.WriteMoveSpell(true, get_selected_slot() + 1) 


func update_spell_slot(slot: int, spell_id: int) -> void:
	var spell_name = ""
	
	# Buscar el nombre del hechizo por su ID
	if spell_id > 0:
		spell_name = GameAssets.GetSpellName(spell_id)
	else:
		spell_name = "(Nada)"
	
	print("Panel de hechizos: DEBUG - update_spell_slot(", slot, ", ", spell_id, ") recibió nombre: ", spell_name)
	
	# Actualizar el item en la lista
	if slot > 0 and slot <= _item_list.item_count:
		_item_list.set_item_text(slot - 1, spell_name)
		if spell_id > 0:
			_item_list.set_item_icon(slot - 1, _get_placeholder_icon())
		else:
			_item_list.set_item_icon(slot - 1, null)
	
	print("Panel de hechizos: actualizado slot ", slot, " con ", spell_name) 


var _placeholder_icon: Texture2D = null

func _get_placeholder_icon() -> Texture2D:
	if _placeholder_icon == null:
		# En Argentum Online, Gfx 15 es un pergamino de hechizos.
		# Intentamos cargarlo; si no existe, usamos un gradiente de color súper premium (púrpura a azul mágico).
		var tex = load("res://Assets/Gfx/15.png")
		if tex:
			_placeholder_icon = tex
		else:
			var gradient = Gradient.new()
			gradient.colors = PackedColorArray([Color("6a1b9a"), Color("283593")]) # Violeta mágico
			var grad_tex = GradientTexture2D.new()
			grad_tex.gradient = gradient
			grad_tex.width = 24
			grad_tex.height = 24
			_placeholder_icon = grad_tex
	return _placeholder_icon
