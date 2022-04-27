extends Node



const KEYS       : Dictionary = {
	network = "NETWORK"
}
var   key_length : int





func _ready() -> void:
	for value in KEYS.values():
		if (len(value) > key_length):
			key_length = len(value)





func network(message : String) -> void:
	message(KEYS.network, message)


func message(key : String, message : String) -> void:
	print("[ " + key.pad_zeros(key_length).replace("0", " ") + " ] " + message)
