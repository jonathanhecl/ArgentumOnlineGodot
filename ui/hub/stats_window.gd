extends Window

# StatsWindow: visualiza Atributos, MiniStats, Fama y Skills (solo lectura)

const SKILL_NAMES = [
	"Magia", "Robar", "Tacticas", "Armas", "Meditar", "Apuñalar", "Ocultarse", "Supervivencia", "Talar", "Comerciar",
	"Defensa", "Pesca", "Mineria", "Carpinteria", "Herreria", "Liderazgo", "Domar", "Proyectiles", "Wrestling", "Navegacion"
]

@onready var attributes_grid: GridContainer = $VBox/Scroll/Content/AttributesSection/AttributesGrid
@onready var ministats_grid: GridContainer = $VBox/Scroll/Content/MiniStatsSection/MiniStatsGrid
@onready var fame_grid: GridContainer = $VBox/Scroll/Content/FameSection/FameGrid
@onready var skills_container: VBoxContainer = $VBox/Scroll/Content/SkillsSection/SkillsList
@onready var close_button: Button = $VBox/ButtonsContainer/CloseButton

var attribute_labels := {}
var ministats_labels := {}
var fame_labels := {}

func _ready() -> void:
	title = "Estadísticas"
	close_button.pressed.connect(self.hide)
	close_requested.connect(self.hide)

	# Construir labels dinámicos
	_build_attribute_labels()
	_build_ministats_labels()
	_build_fame_labels()

func _build_attribute_labels() -> void:
	for n in attributes_grid.get_children():
		n.free()
	var names = ["Fuerza", "Agilidad", "Inteligencia", "Carisma", "Constitución"]
	for attr_name in names:
		var k = attr_name
		var name_label = Label.new()
		name_label.text = attr_name
		var value_label = Label.new()
		value_label.text = "0"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		attributes_grid.add_child(name_label)
		attributes_grid.add_child(value_label)
		attribute_labels[k] = value_label

func _build_ministats_labels() -> void:
	for n in ministats_grid.get_children():
		n.free()
	var pairs = [
		["Ciudadanos Matados", "0"],
		["Criminales Matados", "0"],
		["Usuarios Matados", "0"],
		["NPCs Matados", "0"],
		["Clase", "-"],
		["Pena de Cárcel", "0"]
	]
	for p in pairs:
		var name_label = Label.new()
		name_label.text = p[0]
		var value_label = Label.new()
		value_label.text = p[1]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ministats_grid.add_child(name_label)
		ministats_grid.add_child(value_label)
		ministats_labels[p[0]] = value_label

func _build_fame_labels() -> void:
	for n in fame_grid.get_children():
		n.free()
	var pairs = [
		["Asesino", "0"],
		["Bandido", "0"],
		["Burgués", "0"],
		["Ladrones", "0"],
		["Noble", "0"],
		["Plebe", "0"],
		["Promedio", "0"]
	]
	for p in pairs:
		var name_label = Label.new()
		name_label.text = p[0]
		var value_label = Label.new()
		value_label.text = p[1]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fame_grid.add_child(name_label)
		fame_grid.add_child(value_label)
		fame_labels[p[0]] = value_label

func set_attributes(attributes:Array[int]) -> void:
	var names = ["Fuerza", "Agilidad", "Inteligencia", "Carisma", "Constitución"]
	for i in range(min(5, attributes.size())):
		if attribute_labels.has(names[i]):
			attribute_labels[names[i]].text = str(attributes[i])

func set_skills(skills:Array) -> void:
	for n in skills_container.get_children():
		n.free()
	for i in range(skills.size()):
		var value = 0
		var skill_name = "Skill %d" % (i+1)
		if i < SKILL_NAMES.size():
			skill_name = SKILL_NAMES[i]
		var s = skills[i]
		if s is Object and s.get("level") != null:
			value = int(s.level)
		elif typeof(s) == TYPE_DICTIONARY and s.has("level"):
			value = int(s.level)
		elif typeof(s) in [TYPE_INT, TYPE_FLOAT]:
			value = int(s)
		var h = HBoxContainer.new()
		var lbln = Label.new(); lbln.text = skill_name; lbln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lblv = Label.new(); lblv.text = str(value); lblv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(lbln)
		h.add_child(lblv)
		skills_container.add_child(h)

func set_ministats(ministats:Dictionary) -> void:
	if ministats.has("CiudadanosMatados"): ministats_labels["Ciudadanos Matados"].text = str(ministats.CiudadanosMatados)
	if ministats.has("CriminalesMatados"): ministats_labels["Criminales Matados"].text = str(ministats.CriminalesMatados)
	if ministats.has("UsuariosMatados"): ministats_labels["Usuarios Matados"].text = str(ministats.UsuariosMatados)
	if ministats.has("NpcsMatados"): ministats_labels["NPCs Matados"].text = str(ministats.NpcsMatados)
	if ministats.has("Clase"): ministats_labels["Clase"].text = str(ministats.Clase)
	if ministats.has("PenaCarcel"): ministats_labels["Pena de Cárcel"].text = str(ministats.PenaCarcel)

func set_fame(fame:Dictionary) -> void:
	var fame_map = {
		"Asesino": "AsesinoRep",
		"Bandido": "BandidoRep",
		"Burgués": "BurguesRep",
		"Ladrones": "LadronesRep",
		"Noble": "NobleRep",
		"Plebe": "PlebeRep",
		"Promedio": "Promedio",
	}
	for k in fame_map.keys():
		var key = fame_map[k]
		if fame.has(key):
			fame_labels[k].text = str(fame[key])

func set_data(attributes:Array[int], skills:Array, ministats:Dictionary, fame:Dictionary) -> void:
	set_attributes(attributes)
	set_skills(skills)
	set_ministats(ministats)
	set_fame(fame)
