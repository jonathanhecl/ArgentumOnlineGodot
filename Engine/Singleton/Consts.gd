extends Node

const MapSize = 100
const TileSize = 32
const MaxSkills = 20

const NoAnim = 2
const InfiniteLoops = -1

const MaxNormalInventorySlots = 20
const MaxInventorySlots = 30
const MaxNpcInventorySlots = 50
const MaxInventoryObjs = 10000
const Flagoro = MaxInventorySlots + 1
const MaxBankInventorySlots = 40

const CabezaCasper = 500
const CuerpoFragataFantasmal = 87

const Paso1 = 23
const Paso2 = 24
const PasoNavegando = 25

const ShipIds:Array[int] = [
	# Fragatas
	87, 190, 189, 
	# Embarcaciones normales
	84, 85, 86, 
	# Embarcaciones ciudas
	395, 552, 397, 560, 399, 556, 
	# Embarcaciones reales
	550, 553, 558, 561, 554, 557, 
	# Embarcaciones PK
	396, 398, 400, 
	# Embarcaciones caos
	551, 559, 555
]
