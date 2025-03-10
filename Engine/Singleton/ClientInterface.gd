extends Node

signal connected
signal disconnected
signal dataReceived(data:PackedByteArray)

var _socket:StreamPeerTCP = StreamPeerTCP.new()
var _status:int

func _ready() -> void:
	_status = StreamPeerTCP.STATUS_NONE
	set_process(false)
	
func ConnectToHost(host:String, port:int) -> void:
	_status = StreamPeerTCP.STATUS_NONE
	set_process(_socket.connect_to_host(host, port) == OK)

func DisconnectFromHost() -> void:
	_socket.disconnect_from_host()

func Send(data:PackedByteArray) -> void:
	if _socket.get_status() == StreamPeerTCP.STATUS_CONNECTED && data.size():
		_socket.put_data(data)
		
func _process(_delta: float) -> void:
	_socket.poll()
	var newStatus = _socket.get_status()
	
	if newStatus != _status:
		_status = newStatus
		
		match _status:
			StreamPeerTCP.STATUS_NONE:
				disconnected.emit()
			StreamPeerTCP.STATUS_CONNECTING:
				pass
			StreamPeerTCP.STATUS_CONNECTED:
				connected.emit()
			StreamPeerTCP.STATUS_ERROR:
				disconnected.emit()
			
	if _status == StreamPeerTCP.STATUS_CONNECTED:
		var availableBytes = _socket.get_available_bytes()
		if availableBytes > 0:
			var response = _socket.get_partial_data(availableBytes)
			
			if response[0] != OK:
				disconnected.emit()
				set_process(false);
			else:
				var data = response[1]
				dataReceived.emit(data)
