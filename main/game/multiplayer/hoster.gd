extends Node



var network_peer : NetworkedMultiplayerGodotcord



func _ready() -> void:
	network_peer = NetworkedMultiplayerGodotcord.new()
	network_peer.create_lobby(9, false)
	network_peer.connect("created_lobby", self, "created_lobby")
	get_tree().multiplayer.network_peer = network_peer
	GodotcordActivityManager.connect("activity_invite", self, "join_request_received")


func _exit_tree() -> void:
	network_peer.close_connection()
	get_tree().multiplayer.network_peer = null
	GodotcordActivityManager.disconnect("activity_invite", self, "join_request_received")



func created_lobby() -> void:
	DiscordLink.set_game_state(DiscordLink.GameState.Game)





func join_request_received(type : int, name : String, user_id : int, activity : Dictionary) -> void:
	print("Join request received from", name)
