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
@onready var accept_button = $VBox/ButtonsContainer/AcceptButton
@onready var cancel_button = $VBox/ButtonsContainer/CancelButton

var skill_values: Array[int] = []
var initial_free_skills: int 
var current_free_skills: int  # Puntos de skills locales (no afectan Global hasta aceptar)
var initial_skill_values: Array[int] = []
var skill_labels: Array[Label] = []
var skill_names: Array[String] = []

func _ready():
	title = "Habilidades"
	
	free_skills = $VBox/HBoxContainer/SkillsPts
	accept_button.pressed.connect(_on_accept_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	close_requested.connect(self.hide)
	update_free_skills()
	# Inicialmente deshabilitar el botón de aceptar ya que no hay cambios
	accept_button.disabled = true

# Se llama cuando se presiona el botón + de un skill
func _on_plus_pressed(skill_index: int):
	if current_free_skills > 0 and skill_index < skill_values.size() and skill_values[skill_index] < 100:
		skill_values[skill_index] += 1
		skill_labels[skill_index].text = str(skill_values[skill_index])
		current_free_skills -= 1
		update_free_skills()
		emit_signal("skill_updated", skill_index, skill_values[skill_index])
		update_buttons_state()

# Se llama cuando se presiona el botón - de un skill
func _on_minus_pressed(skill_index: int):
	if (skill_index < skill_values.size() and 
		skill_values[skill_index] > initial_skill_values[skill_index]):
		skill_values[skill_index] -= 1
		skill_labels[skill_index].text = str(skill_values[skill_index])
		current_free_skills += 1
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
				minus_btn.visible = !(i >= skill_values.size() or 
					skill_values[i] <= initial_skill_values[i])
			
			if plus_btn is Button:
				plus_btn.visible = !(i >= skill_values.size() or 
					skill_values[i] >= 100 or current_free_skills <= 0)
	
	# Actualizar el estado del botón de aceptar
	accept_button.disabled = !has_skill_changes()

func update_free_skills():
	free_skills.text = str(current_free_skills)

# Función para verificar si hay cambios en las habilidades
func has_skill_changes() -> bool:
	# Verificar si los puntos libres han cambiado
	if current_free_skills != initial_free_skills:
		return true
	
	# Verificar si algún valor de habilidad ha cambiado
	for i in range(min(skill_values.size(), initial_skill_values.size())):
		if skill_values[i] != initial_skill_values[i]:
			return true
	
	# No hay cambios
	return false

func _on_cancel_pressed():
	# Restaurar los valores originales
	skill_values = initial_skill_values.duplicate()
	current_free_skills = initial_free_skills
	update_free_skills()
	update_buttons_state()
	hide()

func _on_accept_pressed():
	# Aplicar los cambios al Global.skillPoints
	Global.skillPoints = current_free_skills
	
	# Mostrar diferencias en los skills
	var changes = []
	var skills_diff = []
	for i in range(min(initial_skill_values.size(), skill_values.size())):
		skills_diff.append(skill_values[i] - initial_skill_values[i])
		if initial_skill_values[i] != skill_values[i]:
			changes.append("%s: %d -> %d (diff: %d)" % [SKILL_NAMES[i], initial_skill_values[i], skill_values[i], skill_values[i] - initial_skill_values[i]])
	
	if changes.size() > 0:
		print("Cambios en los skills:")
		for change in changes:
			print("- ", change)
		
		# Enviar los skills modificados al servidor
		GameProtocol.WriteModifySkills(skills_diff)
	else:
		print("No se realizaron cambios en los skills")
	
	hide()

func set_skills(skills:Array):
	# Limpiar arrays
	skill_values.clear()
	initial_skill_values.clear()
	skill_labels.clear()
	
	# Eliminar todos los hijos existentes inmediatamente
	for child in skills_container.get_children():
		child.free()  # Usar free() en lugar de queue_free() para eliminación inmediata
	
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
	
	# Inicializar puntos de skills locales
	initial_free_skills = Global.skillPoints
	current_free_skills = Global.skillPoints
	
	_create_skills_interface()
	
	# Actualizar el estado de los botones
	update_buttons_state()
	update_free_skills()

# Nueva función para crear la interfaz de skills
func _create_skills_interface():
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
		# Mostrar el valor del skill
		if i < skill_values.size():
			value_label.text = str(skill_values[i])
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
