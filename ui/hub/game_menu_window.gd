extends Window
class_name GameMenuWindow

signal options_requested
signal return_to_selection_requested
signal quit_requested

@onready var _btn_resume: Button = $MenuPanel/InnerFrame/Margin/VBox/Buttons/BtnResume
@onready var _btn_options: Button = $MenuPanel/InnerFrame/Margin/VBox/Buttons/BtnOptions
@onready var _btn_selection: Button = $MenuPanel/InnerFrame/Margin/VBox/Buttons/BtnSelection
@onready var _btn_quit: Button = $MenuPanel/InnerFrame/Margin/VBox/Buttons/BtnQuit

func _ready() -> void:
	close_requested.connect(hide)
	_btn_resume.pressed.connect(_on_resume_pressed)
	_btn_options.pressed.connect(_on_options_pressed)
	_btn_selection.pressed.connect(_on_selection_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel") \
			or event.is_action_pressed("ExitGame")):
		hide()
		get_viewport().set_input_as_handled()

func _on_resume_pressed() -> void:
	hide()

func _on_options_pressed() -> void:
	hide()
	options_requested.emit()

func _on_selection_pressed() -> void:
	hide()
	return_to_selection_requested.emit()

func _on_quit_pressed() -> void:
	hide()
	quit_requested.emit()
