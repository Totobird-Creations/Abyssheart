extends Node



const SERVER : PackedScene = preload("res://main/game/multiplayer/server.tscn")
const HOSTER : PackedScene = preload("res://main/game/multiplayer/hoster.tscn")
const CLIENT : PackedScene = preload("res://main/game/multiplayer/client.tscn")



func _ready() -> void:
	match (DiscordLink.next_game_state):
		DiscordLink.GameState.GameHost:
			$multiplayer.add_child(SERVER.instance())
			if (DiscordLink.discord_active):
				$multiplayer.add_child(HOSTER.instance())
			else:
				DiscordLink.set_game_state(DiscordLink.GameState.GameSingle)
		DiscordLink.GameState.GameClient:
			if (DiscordLink.discord_active):
				$multiplayer.add_child(CLIENT.instance())
