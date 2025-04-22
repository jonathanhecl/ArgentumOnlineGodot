extends Node

var username:String = ""

signal dialog_font_size_changed(value:int)

var _dialogFontSize:int = 12

var dialogFontSize:int:
    set(value):
        _dialogFontSize = clamp(value, 10, 16)
        emit_signal("dialog_font_size_changed", _dialogFontSize)
    get:
        return _dialogFontSize