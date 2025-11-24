extends Node

# Clave de cifrado XOR (como Security.Redundance en VB6)
# Se inicializa en 13 y luego el servidor puede enviar una nueva clave
var redundance: int = 13

func encrypt_bytes(data: PackedByteArray) -> PackedByteArray:
	"""Cifra los bytes usando XOR con la clave redundance (como NAC_E_Byte en VB6)"""
	var encrypted = PackedByteArray()
	encrypted.resize(data.size())
	
	for i in range(data.size()):
		encrypted[i] = data[i] ^ redundance
	
	return encrypted

func decrypt_bytes(data: PackedByteArray) -> PackedByteArray:
	"""Descifra los bytes usando XOR con la clave redundance (como NAC_D_Byte en VB6)"""
	var decrypted = PackedByteArray()
	decrypted.resize(data.size())
	
	for i in range(data.size()):
		decrypted[i] = data[i] ^ redundance
	
	return decrypted

func set_redundance(new_key: int) -> void:
	"""Actualiza la clave de cifrado (el servidor la envía en el paquete Logged)"""
	redundance = new_key
	print("[Security] Nueva clave de cifrado: ", redundance)

func reset_redundance() -> void:
	"""Resetea la clave a su valor inicial"""
	redundance = 13
	print("[Security] Clave de cifrado reseteada a 13")
