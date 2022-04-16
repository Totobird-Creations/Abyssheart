extends Node



var network_peer : NetworkedMultiplayerGodotcord

var clients      : Dictionary                    = {}



func _ready() -> void:
	network_peer = NetworkedMultiplayerGodotcord.new()
	network_peer.create_lobby(9, false)
	network_peer.connect("created_lobby", self, "created_lobby")
	network_peer.connect("peer_connected", self, "client_connected")
	network_peer.connect("peer_disconnected", self, "client_disconnected")
	get_tree().network_peer = network_peer


func created_lobby() -> void:
	DiscordLink.set_game_state(DiscordLink.GameState.GameHost)

func client_connected(id : int) -> void:
	print(str(network_peer.get_user_id_by_peer(id)) + " connected.")

func client_disconnected(id : int) -> void:
	print(str(network_peer.get_user_id_by_peer(id)) + " disconnected.")


func _exit_tree() -> void:
	network_peer.close_connection()
	get_tree().multiplayer.network_peer = null
