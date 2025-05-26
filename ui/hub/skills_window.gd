extends Window

# Se emite cuando se actualiza un skill
signal skill_updated(skill_index: int, new_value: int)

# Lista de skills y sus nombres
const SKILL_NAMES = [
	"Magia", "Robar", "Tacticas", "Armas", "Meditar", "Apuñalar", "Ocultarse", "Supervivencia", "Talar", "Comerciar",
	"Defensa", "Pesca", "Mineria", "Carpinteria", "Herreria", "Liderazgo", "Domar", "Proyectiles", "Wrestling", "Navegacion"
]

@onready var free_skills: Label
@onready var skills_container = $VBox/Scroll/SkillsContainer
@onready var accept_button = $VBox/AcceptButton

var skill_values: Array[int] = []
var initial_skill_values: Array[int] = []
var skill_labels: Array[Label] = []
var skill_names: Array[String] = []

func _ready():
	free_skills = $VBox/HBoxContainer/SkillsPts
	accept_button.pressed.connect(_on_accept_pressed)
	close_requested.connect(self.hide)
	update_free_skills()

# Se llama cuando se presiona el botón + de un skill
func _on_plus_pressed(skill_index: int):
	if Global.skillPoints > 0 and skill_index < skill_values.size() and skill_values[skill_index] < 100:
		skill_values[skill_index] += 1
		skill_labels[skill_index].text = str(skill_values[skill_index])
		Global.skillPoints -= 1
		update_free_skills()
		emit_signal("skill_updated", skill_index, skill_values[skill_index])
		update_buttons_state()

# Se llama cuando se presiona el botón - de un skill
func _on_minus_pressed(skill_index: int):
	if (skill_index < skill_values.size() and 
		skill_values[skill_index] > initial_skill_values[skill_index]):
		skill_values[skill_index] -= 1
		skill_labels[skill_index].text = str(skill_values[skill_index])
		Global.skillPoints += 1
		update_free_skills()
		emit_signal("skill_updated", skill_index, skill_values[skill_index])
		update_buttons_state()

# Actualiza el estado de los botones + y - según las reglas
func update_buttons_state():
	for i in range(skills_container.get_child_count()):
		var child = skills_container.get_child(i)
		if child is HBoxContainer and child.get_child_count() > 3:
			var minus_btn = child.get_child(1)
			var plus_btn = child.get_child(3)
			
			if minus_btn is Button:
				minus_btn.disabled = (i >= skill_values.size() or 
					skill_values[i] <= initial_skill_values[i])
			
			if plus_btn is Button:
				plus_btn.disabled = (i >= skill_values.size() or 
					skill_values[i] >= 100 or Global.skillPoints <= 0)

func update_free_skills():
	free_skills.text = str(Global.skillPoints)

func _on_accept_pressed():
	# Mostrar diferencias en los skills
	var changes = []
	for i in range(min(initial_skill_values.size(), skill_values.size())):
		if initial_skill_values[i] != skill_values[i]:
			changes.append("%s: %d -> %d (diff: %d)" % [SKILL_NAMES[i], initial_skill_values[i], skill_values[i], skill_values[i] - initial_skill_values[i]])
	
	if changes.size() > 0:
		print("Cambios en los skills:")
		for change in changes:
			print("- ", change)
	else:
		print("No se realizaron cambios en los skills")
	
	hide()

func set_skills(skills:Array):
	# Limpiar arrays
	skill_values.clear()
	initial_skill_values.clear()
	skill_labels.clear()
	
	# Eliminar todos los hijos existentes
	for child in skills_container.get_children():
		child.queue_free()
	
	# Asegurarse de que la ventana tenga un tamaño adecuado y compacto
	size = Vector2(300, 400)
	
	# Inicializar valores de skills
	for i in range(SKILL_NAMES.size()):
		var skill_value = 0
		if i < skills.size():
			if skills[i] is Object and skills[i].get("level") != null:
				skill_value = skills[i].level
			elif typeof(skills[i]) == TYPE_DICTIONARY and skills[i].has("level"):
				skill_value = skills[i].level
			elif typeof(skills[i]) == TYPE_INT or typeof(skills[i]) == TYPE_FLOAT:
				skill_value = int(skills[i])
		skill_values.append(skill_value)
		initial_skill_values.append(skill_value)
	
	for i in range(SKILL_NAMES.size()):
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.custom_minimum_size = Vector2(0, 32)

		var name_label = Label.new()
		name_label.text = SKILL_NAMES[i]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_label.custom_minimum_size = Vector2(120, 0)

		var minus_btn = Button.new()
		minus_btn.text = "-"
		minus_btn.custom_minimum_size = Vector2(30, 0)
		minus_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		minus_btn.pressed.connect(_on_minus_pressed.bind(i))

		var value_label = Label.new()
		# Acceder al valor de forma segura
		if i < skills.size():
			# Los skills vienen como objetos de la clase Skill con propiedades level y experience
			if skills[i] is Object and skills[i].get("level") != null:
				value_label.text = str(skills[i].level)
			elif typeof(skills[i]) == TYPE_DICTIONARY and skills[i].has("level"):
				value_label.text = str(skills[i].level)
			elif typeof(skills[i]) == TYPE_INT or typeof(skills[i]) == TYPE_FLOAT:
				value_label.text = str(skills[i])
			else:
				# Último recurso: intentar convertir directamente
				value_label.text = str(skills[i])
				print("Skill[" + str(i) + "] = ", skills[i], " tipo: ", typeof(skills[i]))
		else:
			value_label.text = "0"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		value_label.custom_minimum_size = Vector2(40, 0)

		var plus_btn = Button.new()
		plus_btn.text = "+"
		plus_btn.custom_minimum_size = Vector2(30, 0)
		plus_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		plus_btn.pressed.connect(_on_plus_pressed.bind(i))

		hbox.add_child(name_label)
		hbox.add_child(minus_btn)
		hbox.add_child(value_label)
		hbox.add_child(plus_btn)
		skills_container.add_child(hbox)
		skill_labels.append(value_label)
		
	update_buttons_state()
