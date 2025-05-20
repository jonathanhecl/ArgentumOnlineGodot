extends Window

# Lista de skills y sus nombres
const SKILL_NAMES = [
	"Magia", "Robar", "Tacticas", "Armas", "Meditar", "Apuñalar", "Ocultarse", "Supervivencia", "Talar", "Comerciar",
	"Defensa", "Pesca", "Mineria", "Carpinteria", "Herreria", "Liderazgo", "Domar", "Proyectiles", "Wrestling", "Navegacion"
]

@onready var free_skills = $VBox/HBoxContainer/SkillsPts
@onready var skills_container = $VBox/Scroll/SkillsContainer
@onready var accept_button = $VBox/AcceptButton

func _ready():
	accept_button.pressed.connect(self.hide)
	close_requested.connect(self.hide)
	
	free_skills.text = "3434"

func set_skills(skills:Array):
	# Eliminar todos los hijos existentes
	for child in skills_container.get_children():
		child.queue_free()
	
	# Asegurarse de que la ventana tenga un tamaño adecuado y compacto
	size = Vector2(300, 400)
	
	# Debug detallado para ver la estructura exacta de los datos
	print("VENTANA: Skills recibidos - Cantidad: ", skills.size())
	for i in range(min(skills.size(), 20)): # Mostrar todos los skills
		print("VENTANA: Skill[", i, "] = ", skills[i], " - Tipo: ", typeof(skills[i]))
		
		# Intentar acceder a las propiedades de diferentes maneras
		if skills[i] is Object:
			var properties = ["level", "experience"]
			for prop in properties:
				if skills[i].get(prop) != null:
					print("VENTANA: Skill[", i, "].", prop, " = ", skills[i].get(prop))
				else:
					print("VENTANA: Skill[", i, "] no tiene propiedad '", prop, "'")
					
		# Si es diccionario, mostrar sus claves
		if typeof(skills[i]) == TYPE_DICTIONARY:
			print("VENTANA: Skill[", i, "] claves: ", skills[i].keys())
	
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
		minus_btn.pressed.connect(func(): print("Quitar punto a ", SKILL_NAMES[i]))

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
		plus_btn.pressed.connect(func(): print("Agregar punto a ", SKILL_NAMES[i]))

		hbox.add_child(name_label)
		hbox.add_child(minus_btn)
		hbox.add_child(value_label)
		hbox.add_child(plus_btn)
		skills_container.add_child(hbox)
