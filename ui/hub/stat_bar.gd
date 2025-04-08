extends TextureProgressBar
class_name StatBar

@onready var label: Label = $Label


func _on_changed() -> void:
	_update_label()


func _on_value_changed(_v: float) -> void:
	_update_label()


func _update_label() -> void:
	label.text = "%d/%d" % [value, max_value]
