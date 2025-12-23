extends TextureRect
class_name SpellListPanel

@onready var _item_list: ItemList = $ItemList

func _ready() -> void:
	for i in Consts.MaxUserHechizos:
		_item_list.add_item("(None)")
	
	# Conectar la selección de hechizos al sistema de macro
	_item_list.item_selected.connect(_on_spell_selected)


func get_selected_slot() -> int:
	var selected_item = _item_list.get_selected_items()
	if selected_item.is_empty():
		return -1
	return selected_item[0]


func set_slot_text(slot:int, text:String) -> void:
	_item_list.set_item_text(slot, text)


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
	if slot == -1 || _item_list.get_item_text(slot) == "(None)": 
		return 
		
	GameProtocol.WriteCastSpell(slot + 1)
	GameProtocol.WriteWork(Enums.Skill.Magia)


func _on_btn_info_pressed() -> void:
	if get_selected_slot() == -1: return
	GameProtocol.WriteSpellInfo(get_selected_slot() + 1)


func _on_btn_move_up_pressed() -> void:
	if get_selected_slot() <= 0: return
	_item_list.move_item(get_selected_slot(), get_selected_slot() - 1)
	_item_list.select(get_selected_slot())
	GameProtocol.WriteMoveSpell(false, get_selected_slot() + 1) 


func _on_btn_move_down_pressed() -> void:
	if get_selected_slot() != -1 && get_selected_slot() + 1 ==  Consts.MaxUserHechizos: return
	_item_list.move_item(get_selected_slot(), get_selected_slot() + 1)
	_item_list.select(get_selected_slot())
	GameProtocol.WriteMoveSpell(true, get_selected_slot() + 1) 


func update_spell_slot(slot: int, spell_id: int) -> void:
	var spell_name = ""
	
	# Buscar el nombre del hechizo por su ID
	if spell_id > 0:
		# TODO: Cargar los nombres de hechizos desde un archivo de datos
		# Por ahora, mostrar el ID
		spell_name = "Hechizo " + str(spell_id)
	else:
		spell_name = "(None)"
	
	# Actualizar el item en la lista
	if slot > 0 and slot <= _item_list.item_count:
		_item_list.set_item_text(slot - 1, spell_name)
	
	print("Panel de hechizos: actualizado slot ", slot, " con ", spell_name) 
