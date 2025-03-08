extends Panel
class_name SpellList

@export var _itemList:ItemList

func _ready() -> void:
	for i in Consts.MaxUserHechizos:
		_itemList.add_item("(None)")
		
func GetSelectedSlot() -> int:
	var selected_item = _itemList.get_selected_items()
	if selected_item.is_empty():
		return -1
	return selected_item[0]

func _OnInfoPressed() -> void:
	if GetSelectedSlot() == -1: return
	GameProtocol.WriteSpellInfo(GetSelectedSlot() + 1)
	
func SetSlotText(slot:int, text:String) -> void:
	_itemList.set_item_text(slot, text)

func _OnCastPressed() -> void:
	if GetSelectedSlot() == -1 || _itemList.get_item_text(GetSelectedSlot()) == "(None)": 
		return 
		
	GameProtocol.WriteCastSpell(GetSelectedSlot() + 1)
	GameProtocol.WriteWork(Enums.Skill.Magia)

func _OnMoveDownPressed() -> void:
	if GetSelectedSlot() != -1 && GetSelectedSlot() + 1 ==  Consts.MaxUserHechizos: return
	_itemList.move_item(GetSelectedSlot(), GetSelectedSlot() + 1)
	_itemList.select(GetSelectedSlot())
	GameProtocol.WriteMoveSpell(true, GetSelectedSlot() + 1) 

func _OnMoveUpPressed() -> void:
	if GetSelectedSlot() <= 0: return
	_itemList.move_item(GetSelectedSlot(), GetSelectedSlot() - 1)
	_itemList.select(GetSelectedSlot())
	GameProtocol.WriteMoveSpell(false, GetSelectedSlot() + 1) 
