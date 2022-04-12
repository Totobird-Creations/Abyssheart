extends Node



enum GameState {
	Menu,
	Game
}
var game_state  : int  = GameState.Menu setget set_game_state
var start       : int  = OS.get_unix_time()





func set_game_state(value : int) -> void:
	game_state = value
	update_activity()





func _ready() -> void:
	Godotcord.init(962773221130797126, Godotcord.CreateFlags_DEFAULT);
	update_activity()



func _process(_delta : float) -> void:
	Godotcord.run_callbacks()



func _exit_tree() -> void:
	GodotcordActivityManager.clear_activity()





func update_activity() -> void:
	var activity : GodotcordActivity = GodotcordActivity.new()

	match (game_state):
		GameState.Menu:
			activity.details = "Menu"
		GameState.Game: 
			activity.details = "Game"
			var network_peer := get_tree().multiplayer.network_peer
			if (network_peer is NetworkedMultiplayerGodotcord):
				activity.join_secret = network_peer.get_lobby_secret()
	activity.start       = start
	activity.large_image = "spore"

	GodotcordActivityManager.set_activity(activity)
