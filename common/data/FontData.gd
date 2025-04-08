extends RefCounted
class_name FontData

var color:Color
var bold:bool
var italic:bool

func _init(pColor:Color = Color.WHITE, pBold:bool = false, pItalic:bool = false) -> void:
	color = pColor
	bold = pBold
	italic = pItalic
