extends Node



var clients : Dictionary = {}



func _ready() -> void:
	DiscordLink.network_peer.connect("created_lobby", self, "created_lobby")
	DiscordLink.network_peer.connect("peer_connected", self, "client_connected")
	DiscordLink.network_peer.connect("peer_disconnected", self, "client_disconnected")


func created_lobby() -> void:
	DiscordLink.update_activity()

func client_connected(peer_id : int) -> void:
	var user_id := DiscordLink.network_peer.get_user_id_by_peer(peer_id)
	GodotcordUserManager.get_user(user_id)
	var user : GodotcordUser = yield(GodotcordUserManager, "get_user_callback")
	clients[peer_id] = {
		peer_id = peer_id,
		user_id = user_id,
		user    = user
	}
	print(str(user.name) + " connected.")

func client_disconnected(peer_id : int) -> void:
	var client : Dictionary = clients[peer_id]
	print(str(client.user.name) + " disconnected.")
	clients.erase(peer_id)


func _exit_tree() -> void:
	DiscordLink.network_peer.close_connection()
	get_tree().network_peer = null
