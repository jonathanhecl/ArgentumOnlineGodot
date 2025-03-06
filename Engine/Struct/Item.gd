extends RefCounted
class_name Item

const EquippableTypes = \
[
	Enums.eOBJType.eOBJType_otWeapon,
	Enums.eOBJType.eOBJType_otESCUDO,
	Enums.eOBJType.eOBJType_otArmadura,
	Enums.eOBJType.eOBJType_otCASCO,
	Enums.eOBJType.eOBJType_otFlechas,
	Enums.eOBJType.eOBJType_otAnillo
]

const UsableTypes = \
[
	Enums.eOBJType.eOBJType_otPociones,
	Enums.eOBJType.eOBJType_otBebidas,
	Enums.eOBJType.eOBJType_otPergaminos,
	Enums.eOBJType.eOBJType_otGuita,
	Enums.eOBJType.eOBJType_otUseOnce
]

var index:int
var name:String

var icon:Texture2D
var type:int

var maxHit:int
var minHit:int

var maxDef:int
var minDef:int

var salePrice:int

func IsEquippable() -> bool:
	return type in EquippableTypes
	 
func IsUsable() -> bool:
	return type in UsableTypes

func IsWeapon() -> bool:
	return type == Enums.eOBJType.eOBJType_otWeapon
	
func IsArmour() -> bool:
	return type in [Enums.eOBJType.eOBJType_otArmadura,\
					Enums.eOBJType.eOBJType_otESCUDO,\
					Enums.eOBJType.eOBJType_otCASCO]
