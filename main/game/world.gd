extends Node



const SERVER : PackedScene = preload("res://main/game/multiplayer/server.tscn")
const HOSTER : PackedScene = preload("res://main/game/multiplayer/hoster.tscn")
const CLIENT : PackedScene = preload("res://main/game/multiplayer/client.tscn")



func _ready() -> void:
	match (DiscordLink.game_state):

		DiscordLink.GameState.GameHost:
			$service.add_child(SERVER.instance())
			if (DiscordLink.discord_active):
				$service.add_child(HOSTER.instance())

		DiscordLink.GameState.GameClient:
			$service.add_child(CLIENT.instance())



remote func spawn_entity(path : String, data : Dictionary) -> void:
	var instance : Entity = load(path).instance()
	instance.load_data(data)
	$entities.add_child(instance)
