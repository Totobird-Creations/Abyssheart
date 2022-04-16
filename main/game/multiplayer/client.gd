extends Node



func _ready() -> void:
	DiscordLink.network_peer.connect("connection_succeeded", self, "connection_success")
	DiscordLink.network_peer.connect("connection_failed", self, "connection_failure")


func connection_success() -> void:
	DiscordLink.update_activity()

func connection_failure() -> void:
	pass


func _exit_tree() -> void:
	DiscordLink.network_peer.close_connection()
	get_tree().network_peer = null
