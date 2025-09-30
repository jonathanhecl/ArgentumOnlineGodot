extends Window

# StatsWindow: visualiza Atributos, MiniStats, Fama y Skills (solo lectura)

const SKILL_NAMES = [
	"Magia", "Robar", "Tacticas", "Armas", "Meditar", "Apuñalar", "Ocultarse", "Supervivencia", "Talar", "Comerciar",
	"Defensa", "Pesca", "Mineria", "Carpinteria", "Herreria", "Liderazgo", "Domar", "Proyectiles", "Wrestling", "Navegacion"
]

const VALUE_COL_MIN_WIDTH := 56

# Optional mapping from class id to name (adjust to your server mapping)
const CLASS_NAMES := {
	0: "-",
	1: "Guerrero",
	2: "Mago",
	3: "Clérigo",
	4: "Asesino",
	5: "Bardo",
	6: "Druida",
	7: "Paladín",
	8: "Cazador",
}

func _class_to_text(v) -> String:
	match typeof(v):
		TYPE_INT:
			if CLASS_NAMES.has(v):
				return String(CLASS_NAMES[v])
			return "Clase %d" % int(v)
		TYPE_STRING:
			return String(v)
		_:
			return str(v)

@onready var attributes_grid: GridContainer = $VBox/Columns/LeftColumn/LeftPadding/LeftContent/AttributesPadding/AttributesSection/AttributesGrid
@onready var ministats_grid: GridContainer = $VBox/Columns/RightColumn/RightPadding/RightContent/MiniStatsSection/MiniStatsGrid
@onready var fame_grid: GridContainer = $VBox/Columns/RightColumn/RightPadding/RightContent/FameSection/FameGrid
@onready var skills_container: VBoxContainer = $VBox/Columns/LeftColumn/LeftPadding/LeftContent/SkillsPadding/SkillsScroll/SkillsSection/SkillsList
@onready var close_button: Button = $VBox/ButtonsContainer/CloseButton

const BASE_WIDTH := 460.0
const BASE_FONT := 14
const MIN_FONT := 10

var attribute_labels := {}
var ministats_labels := {}
var fame_labels := {}
var _ui_ready := false

# Datos pendientes si llegan antes de _ready()
var _pending_attributes = null
var _pending_skills = null
var _pending_ministats = null
var _pending_fame = null

func _ready() -> void:
	title = "Estadísticas"
	close_button.pressed.connect(self.hide)
	close_requested.connect(self.hide)
	# Recalcular fuentes al cambiar tamaño de la ventana
	self.connect("resized", Callable(self, "_update_font_scale"))

	# Construir labels dinámicos
	_build_attribute_labels()
	_build_ministats_labels()
	_build_fame_labels()
	_update_font_scale()
	_ui_ready = true
	# Si había datos que llegaron antes de construir la UI, aplicarlos ahora
	if _pending_attributes != null:
		set_attributes(_pending_attributes)
		_pending_attributes = null
	if _pending_skills != null:
		set_skills(_pending_skills)
		_pending_skills = null
	if _pending_ministats != null:
		set_ministats(_pending_ministats)
		_pending_ministats = null
	if _pending_fame != null:
		set_fame(_pending_fame)
		_pending_fame = null

func _resolve_ui_refs() -> void:
	if attributes_grid == null:
		attributes_grid = get_node_or_null("VBox/Columns/LeftColumn/LeftPadding/LeftContent/AttributesPadding/AttributesSection/AttributesGrid")
	if ministats_grid == null:
		ministats_grid = get_node_or_null("VBox/Columns/RightColumn/RightPadding/RightContent/MiniStatsSection/MiniStatsGrid")
	if fame_grid == null:
		fame_grid = get_node_or_null("VBox/Columns/RightColumn/RightPadding/RightContent/FameSection/FameGrid")
	if skills_container == null:
		skills_container = get_node_or_null("VBox/Columns/LeftColumn/LeftPadding/LeftContent/SkillsPadding/SkillsScroll/SkillsSection/SkillsList")

func _update_font_scale() -> void:
	var factor: float = clamp(float(size.x) / BASE_WIDTH, 0.75, 1.0)
	var fsize: int = int(round(BASE_FONT * factor))
	if fsize < MIN_FONT:
		fsize = MIN_FONT
	_apply_font_size(fsize)

func _apply_font_size(font_size: int) -> void:
	# Recorre todos los Labels de las dos columnas y aplica override de tamaño
	var roots := [
		$VBox/Columns/LeftColumn,
		$VBox/Columns/RightColumn
	]
	for r in roots:
		_apply_font_size_recursive(r, font_size)

func _apply_font_size_recursive(node: Node, font_size: int) -> void:
	for child in node.get_children():
		if child is Label:
			(child as Label).add_theme_font_size_override("font_size", font_size)
		if child.get_child_count() > 0:
			_apply_font_size_recursive(child, font_size)

func _build_attribute_labels() -> void:
	for n in attributes_grid.get_children():
		n.free()
	var names = ["Fuerza", "Agilidad", "Inteligencia", "Carisma", "Constitución"]
	for attr_name in names:
		var k = attr_name
		var name_label = Label.new()
		name_label.text = attr_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label = Label.new()
		value_label.text = "0"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(VALUE_COL_MIN_WIDTH, 0)
		value_label.size_flags_horizontal = 0
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
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label = Label.new()
		value_label.text = p[1]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(VALUE_COL_MIN_WIDTH, 0)
		value_label.size_flags_horizontal = 0
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
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value_label = Label.new()
		value_label.text = p[1]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(VALUE_COL_MIN_WIDTH, 0)
		value_label.size_flags_horizontal = 0
		fame_grid.add_child(name_label)
		fame_grid.add_child(value_label)
		fame_labels[p[0]] = value_label

func set_attributes(attributes:Array[int]) -> void:
	if !_ui_ready:
		_pending_attributes = attributes
		return
	var names = ["Fuerza", "Agilidad", "Inteligencia", "Carisma", "Constitución"]
	for i in range(min(5, attributes.size())):
		if attribute_labels.has(names[i]):
			attribute_labels[names[i]].text = str(attributes[i])

func set_skills(skills:Array) -> void:
	if !_ui_ready:
		_pending_skills = skills
		return
	_resolve_ui_refs()
	if skills_container == null:
		push_warning("StatsWindow: skills_container es null. set_skills diferido.")
		_pending_skills = skills
		return
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
		h.add_theme_constant_override("separation", 12)
		var lbln = Label.new(); lbln.text = skill_name; lbln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lblv = Label.new(); lblv.text = str(value); lblv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; lblv.custom_minimum_size = Vector2(VALUE_COL_MIN_WIDTH, 0); lblv.size_flags_horizontal = 0
		h.add_child(lbln)
		h.add_child(lblv)
		skills_container.add_child(h)
	# Asegurar que las nuevas etiquetas respeten el tamaño actual de fuente
	_update_font_scale()

func set_ministats(ministats:Dictionary) -> void:
	if !_ui_ready:
		_pending_ministats = ministats
		return
	# Asignaciones básicas
	if ministats.has("CiudadanosMatados"): ministats_labels["Ciudadanos Matados"].text = str(ministats.CiudadanosMatados)
	if ministats.has("CriminalesMatados"): ministats_labels["Criminales Matados"].text = str(ministats.CriminalesMatados)
	if ministats.has("UsuariosMatados"): ministats_labels["Usuarios Matados"].text = str(ministats.UsuariosMatados)
	if ministats.has("NpcsMatados"): ministats_labels["NPCs Matados"].text = str(ministats.NpcsMatados)
	# Clase: preferir nombre textual si está disponible
	var clase_nombre_keys = ["ClaseNombre", "ClaseName", "ClaseTexto", "ClaseStr"]
	var clase_set := false
	for k in clase_nombre_keys:
		if ministats.has(k):
			ministats_labels["Clase"].text = str(ministats[k])
			clase_set = true
			break
	if !clase_set and ministats.has("Clase"):
		ministats_labels["Clase"].text = _class_to_text(ministats.Clase)
	if ministats.has("PenaCarcel"):
		ministats_labels["Pena de Cárcel"].text = str(ministats.PenaCarcel)

func set_fame(fame:Dictionary) -> void:
	if !_ui_ready:
		_pending_fame = fame
		return
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
