extends Node

signal connected
signal disconnected
signal connection_timeout
signal dataReceived(data: PackedByteArray)

# Constante para habilitar/deshabilitar el log de paquetes
const LOG_PACKETS := true

# Timeout de conexión en segundos
const CONNECTION_TIMEOUT := 10.0

# Transporte TCP (desktop)
var _socket: StreamPeerTCP = null
var _status: int

# Transporte WebSocket (web)
var _ws: WebSocketPeer = null
var _is_web: bool = false

var _connection_timer: float = 0.0
var _is_connecting: bool = false

func _ready() -> void:
	_is_web = OS.has_feature("web")
	if _is_web:
		_ws = WebSocketPeer.new()
	else:
		_socket = StreamPeerTCP.new()
		_status = StreamPeerTCP.STATUS_NONE
	_is_connecting = false
	_connection_timer = 0.0
	set_process(false)

func ConnectToHost(host: String, port: int) -> void:
	_connection_timer = 0.0
	_is_connecting = true
	if _is_web:
		var url = "ws://%s:%d" % [host, port]
		var err = _ws.connect_to_url(url)
		set_process(err == OK)
	else:
		_status = StreamPeerTCP.STATUS_NONE
		set_process(_socket.connect_to_host(host, port) == OK)

func DisconnectFromHost() -> void:
	_is_connecting = false
	_connection_timer = 0.0
	if _is_web:
		_ws.close()
	else:
		_socket.disconnect_from_host()

func Send(data: PackedByteArray) -> void:
	var transport_connected = _ws.get_ready_state() == WebSocketPeer.STATE_OPEN if _is_web \
		else _socket.get_status() == StreamPeerTCP.STATUS_CONNECTED
	if not transport_connected or data.size() == 0:
		return
	# NOTA: El cifrado solo se usa si el servidor tiene AntiExternos habilitado
	# AOGolang NO tiene AntiExternos, así que enviamos los datos sin cifrar
	var data_to_send = data
	if Security.anti_externos_enabled:
		data_to_send = Security.encrypt_bytes(data)
		if LOG_PACKETS:
			print("[OUTGOING] Enviando %d bytes cifrados" % data_to_send.size() + " DATA original: " + Utils.BytesToDecimal(data))
	else:
		if LOG_PACKETS:
			print("[OUTGOING] Enviando %d bytes sin cifrar" % data_to_send.size() + " DATA original: " + Utils.BytesToDecimal(data))
	if _is_web:
		_ws.send(data_to_send, WebSocketPeer.WRITE_MODE_BINARY)
	else:
		_socket.put_data(data_to_send)

func _process(delta: float) -> void:
	if _is_web:
		_process_websocket(delta)
	else:
		_process_tcp(delta)

func _process_tcp(delta: float) -> void:
	_socket.poll()
	var newStatus = _socket.get_status()

	if _is_connecting:
		_connection_timer += delta
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
				set_process(false)
			else:
				_handle_incoming_data(response[1])

func _process_websocket(delta: float) -> void:
	_ws.poll()
	var state = _ws.get_ready_state()

	if _is_connecting:
		_connection_timer += delta
		if _connection_timer >= CONNECTION_TIMEOUT:
			_is_connecting = false
			_connection_timer = 0.0
			_ws.close()
			set_process(false)
			connection_timeout.emit()
			return

	match state:
		WebSocketPeer.STATE_OPEN:
			if _is_connecting:
				_is_connecting = false
				_connection_timer = 0.0
				connected.emit()
			while _ws.get_available_packet_count() > 0:
				var data = _ws.get_packet()
				_handle_incoming_data(data)
		WebSocketPeer.STATE_CLOSED:
			if _is_connecting or not _is_connecting:
				_is_connecting = false
				set_process(false)
				disconnected.emit()

func _handle_incoming_data(data: PackedByteArray) -> void:
	# El servidor NO envía datos cifrados, solo el cliente cifra al enviar.
	# Por lo tanto, usamos los datos tal cual llegan.
	if LOG_PACKETS and data.size() > 0:
		var packet_id = -1
		var packet_length = 0
		if data.size() >= 1:
			packet_id = data[0]
		if data.size() >= 3:
			packet_length = (data[2] << 8) | data[1]
		var dec_str = Utils.BytesToDecimal(data)
		print("[INCOMING] Packet ID: %d (0x%02X), Longitud: %d, Bytes: %s" % [packet_id, packet_id, packet_length, dec_str])
	dataReceived.emit(data)
