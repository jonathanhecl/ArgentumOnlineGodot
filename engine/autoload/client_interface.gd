extends Node

signal connected
signal disconnected
signal connection_timeout
signal dataReceived(data:PackedByteArray)

# Constante para habilitar/deshabilitar el log de paquetes
const LOG_PACKETS := true

# Timeout de conexión en segundos
const CONNECTION_TIMEOUT := 10.0

var _socket:StreamPeerTCP = StreamPeerTCP.new()
var _status:int
var _connection_timer: float = 0.0
var _is_connecting: bool = false

func _ready() -> void:
	_status = StreamPeerTCP.STATUS_NONE
	_is_connecting = false
	_connection_timer = 0.0
	set_process(false)
	
func ConnectToHost(host:String, port:int) -> void:
	_status = StreamPeerTCP.STATUS_NONE
	_connection_timer = 0.0
	_is_connecting = true
	set_process(_socket.connect_to_host(host, port) == OK)

func DisconnectFromHost() -> void:
	_socket.disconnect_from_host()
	_is_connecting = false
	_connection_timer = 0.0

func Send(data:PackedByteArray) -> void:
	if _socket.get_status() == StreamPeerTCP.STATUS_CONNECTED && data.size():
		# Cifrar los datos antes de enviar (como en VB6 con Security.NAC_E_Byte)
		var encrypted_data = Security.encrypt_bytes(data)
		if LOG_PACKETS:
			print("[OUTGOING] Enviando %d bytes cifrados (original: %d bytes)" % [encrypted_data.size(), data.size()])
		_socket.put_data(encrypted_data)
		
func _process(_delta: float) -> void:
	_socket.poll()
	var newStatus = _socket.get_status()
	
	# Verificar timeout de conexión
	if _is_connecting:
		_connection_timer += _delta
		if _connection_timer >= CONNECTION_TIMEOUT:
			_is_connecting = false
			_connection_timer = 0.0
			_socket.disconnect_from_host()
			set_process(false)
			connection_timeout.emit()
			return
	
	if newStatus != _status:
		_status = newStatus
		
		match _status:
			StreamPeerTCP.STATUS_NONE:
				_is_connecting = false
				disconnected.emit()
			StreamPeerTCP.STATUS_CONNECTING:
				pass
			StreamPeerTCP.STATUS_CONNECTED:
				_is_connecting = false
				_connection_timer = 0.0
				connected.emit()
			StreamPeerTCP.STATUS_ERROR:
				_is_connecting = false
				disconnected.emit()
			
	if _status == StreamPeerTCP.STATUS_CONNECTED:
		var availableBytes = _socket.get_available_bytes()
		if availableBytes > 0:
			var response = _socket.get_partial_data(availableBytes)
			
			if response[0] != OK:
				disconnected.emit()
				set_process(false);
			else:
				var encrypted_data = response[1]
				# Descifrar los datos recibidos (como en VB6 con Security.NAC_D_Byte)
				var data = Security.decrypt_bytes(encrypted_data)
				
				# FIX: Detectar si el servidor envió un paquete ShowMessageBox (25) sin cifrar
				# Esto ocurre cuando hay error de versión, el servidor envía el error y cierra la conexión sin cifrar
				if Security.redundance == 13 and encrypted_data.size() > 3:
					if encrypted_data[0] == 25: # ShowMessageBox
						var msg_len = encrypted_data[1] | (encrypted_data[2] << 8)
						# Si el largo coincide exactamente con el buffer recibido, es muy probable que sea texto plano
						# 3 bytes de header (ID + Length) + Length bytes de payload
						if msg_len + 3 == encrypted_data.size():
							print("[Security] Detectado paquete ShowMessageBox no cifrado. Usando datos sin descifrar.")
							data = encrypted_data

				if LOG_PACKETS and data.size() > 0:
					# Mostrar información básica del paquete
					var packet_id = -1
					var packet_length = 0
					
					# Obtener el ID del paquete (primer byte)
					if data.size() >= 1:
						packet_id = data[0]
					
					# Obtener la longitud del paquete (bytes 2 y 3, little-endian)
					if data.size() >= 3:
						packet_length = (data[2] << 8) | data[1]
					
					# Convertir los bytes a formato legible
					var hex_str = ""
					for i in range(0, data.size()):
						hex_str += "%02X " % data[i]
					
					# Mostrar información del paquete
					print("[INCOMING] Packet ID: %d (0x%02X), Longitud: %d, Bytes: %s" % [packet_id, packet_id, packet_length, hex_str])
				
				dataReceived.emit(data)
