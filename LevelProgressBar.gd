extends PanelContainer
class_name LevelProgressBar

var _levelMax:bool
var _tween:Tween

@export var animate:bool

func SetLevel(level:int) -> void:
	%Level.text = str(level)

func SetExperience(value:int) -> void:
	if _levelMax:
		return
		
	if animate:
		if _tween:
			_tween.kill()
		_tween = create_tween() 
		_tween.tween_property(%ExperienceBar, "value", value, 0.5).set_ease(Tween.EASE_OUT)
	else:
		%ExperienceBar.value = value 
		
	%ExperienceLabel.text = "{0}/{1}".format([value, int(%ExperienceBar.max_value)])
	
func SetMaxExperience(value:int) -> void:
	if _levelMax:
		return
	
	if animate:
		if _tween:
			_tween.kill()
			_tween = null  
			
	%ExperienceBar.max_value = value
	%ExperienceLabel.text = "{0}/{1}".format([int(%ExperienceBar.value), value])
	
func SetLevelMax() -> void:
	_levelMax = true
	%ExperienceBar.show_percentage = false
	%ExperienceLabel.show()
	%ExperienceLabel.text = "Nivel Maximo"
	
func _gui_input(event: InputEvent) -> void:
	if _levelMax:
		return
