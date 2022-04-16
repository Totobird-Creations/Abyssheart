extends Node



var network_peer : NetworkedMultiplayerGodotcord



func _ready() -> void:
	network_peer = NetworkedMultiplayerGodotcord.new()
	network_peer.join_server_activity(DiscordLink.join_secret)
	network_peer.connect("connection_succeeded", self, "connection_success")
	network_peer.connect("connection_failed", self, "connection_failure")
	get_tree().network_peer = network_peer
	DiscordLink.set_game_state(DiscordLink.GameState.GameClient)


func connection_success() -> void:
	print("success")

func connection_failure() -> void:
	print("failed")


func _exit_tree() -> void:
	network_peer.close_connection()
	get_tree().multiplayer.network_peer = null
