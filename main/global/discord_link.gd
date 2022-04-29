extends Node



var S_Godotcord
var S_GodotcordActivityManager
var S_GodotcordActivity
var S_GodotcordRelationshipManager
var S_GodotcordRelationship
var S_GodotcordUserManager
var S_NetworkedMultiplayerGodotcord

const PATH_PLAYER : String = "res://main/game/entity/player.tscn"

enum NotificationType {
	DiscordInactive,
	JoinRequest,
	Invite,
	Join
}
enum GameState {
	Menu,
	GameHost,
	GameClient
}

const APPLICATION_ID     : int        = 962773221130797126
const SERVER_ID          : int        = 1

const ICON_RELOAD        : Texture    = preload("res://assets/texture/interface/icon/reload.png")

var discord_active       : bool       = false
var has_started          : bool       = false
var game_state           : int                           = GameState.Menu setget set_game_state
var start                : int                           = OS.get_unix_time()

var notification_queue   : Array                         = []
var notification_current : Dictionary                    = {}

var network_peer         : NetworkedMultiplayerPeer





func set_game_state(value : int, secret : String = "") -> void:
	if (value != game_state):
		# Clean up previous state
		match (game_state):

			GameState.Menu:
				# Remove discord inactive notification.
				var new_notification_queue := []
				for notification in notification_queue:
					if (notification.type != NotificationType.DiscordInactive):
						new_notification_queue.append(notification)
				notification_queue = new_notification_queue
				if (len(notification_current.keys()) >= 1 && notification_current.type == NotificationType.DiscordInactive):
					notification_dismiss()

			GameState.GameHost:
				# Remove join request notifications.
				var new_notification_queue := []
				for notification in notification_queue:
					if (notification.type != NotificationType.JoinRequest):
						new_notification_queue.append(notification)
				notification_queue = new_notification_queue
				if (len(notification_current.keys()) >= 1 && notification_current.type == NotificationType.JoinRequest):
					notification_decline()

		# Set new state
		game_state = value

		# Set up new state
		match (game_state):

			GameState.Menu:
				SceneSwitcher.switch_scene("res://main/menu/main.tscn")

			GameState.GameHost:
				if (discord_active):
					network_peer = S_NetworkedMultiplayerGodotcord.new()
					network_peer.create_lobby(10, false)
					get_tree().set_network_peer(network_peer)
				SceneSwitcher.switch_scene("res://main/game/world.tscn")

			GameState.GameClient:
				network_peer = S_NetworkedMultiplayerGodotcord.new()
				network_peer.join_server_activity(secret)
				get_tree().set_network_peer(network_peer)
				SceneSwitcher.switch_scene("res://main/game/world.tscn")

	update_activity()





func start() -> void:
	has_started = true
	var error := -1
	if (Engine.has_singleton("Godotcord")):
		S_Godotcord                     = Engine.get_singleton("Godotcord")
		S_GodotcordActivityManager      = Engine.get_singleton("GodotcordActivityManager")
		S_GodotcordActivity             = Engine.get_singleton("GodotcordActivity")
		S_GodotcordRelationshipManager  = Engine.get_singleton("GodotcordRelationshipManager")
		S_GodotcordRelationship         = Engine.get_singleton("GodotcordRelationship")
		S_GodotcordUserManager          = Engine.get_singleton("GodotcordUserManager")
		S_NetworkedMultiplayerGodotcord = Engine.get_singleton("NetworkedMultiplayerGodotcord")
		error = S_Godotcord.init(APPLICATION_ID, S_Godotcord.CreateFlags_NO_REQUIRE_DISCORD)
		if (error == OK):
			discord_active = true
			update_activity()

			S_GodotcordActivityManager.connect("activity_join_request", self, "join_request_received")
			S_GodotcordActivityManager.connect("activity_join", self, "join_pressed_in_discord")

	if (error != OK):
		discord_active = false
		notification_queue.append({
			type = NotificationType.DiscordInactive,
		})



func _process(delta : float) -> void:
	if (! has_started):
		return

	if (discord_active):
		S_Godotcord.run_callbacks()

	if (len(notification_current.keys()) <= 0 && len(notification_queue) >= 1):
		notification_current = notification_queue[0]
		notification_queue.remove(0)
		$viewport/notification/progress/bar.anchor_right = 0.0
		$viewport/notification/toggle.play("main")
		$viewport/notification/timeout.start()
		match (notification_current.type):
			NotificationType.DiscordInactive:
				$viewport/notification/message.text           = "Discord not detected. Multiplayer is disabled."
				$viewport/notification/icon.material.set_shader_param("icon", ICON_RELOAD)
				$viewport/notification/accept_decline.visible = false
				$viewport/notification/reload.visible         = true
				$viewport/notification/reload/reload.text     = "Quit"
				$viewport/notification/reload/dismiss.text    = "Dismiss"
				$viewport/notification/timeout.stop()
			NotificationType.JoinRequest:
				$viewport/notification/message.text                = notification_current.user_name + " #" + notification_current.user_discriminator + " has requested to join. Hold enter to accept."
				$viewport/notification/accept_decline.visible      = true
				$viewport/notification/reload.visible              = false
				$viewport/notification/accept_decline/accept.text  = "Accept"
				$viewport/notification/accept_decline/decline.text = "Decline"
			NotificationType.Invite:
				$viewport/notification/message.text                = notification_current.user_name + " #" + notification_current.user_discriminator + " has invited you to their game."
				$viewport/notification/accept_decline.visible      = true
				$viewport/notification/reload.visible              = false
				$viewport/notification/accept_decline/accept.text  = "Accept"
				$viewport/notification/accept_decline/decline.text = "Decline"
			NotificationType.Join:
				$viewport/notification/message.text                = "Confirm join friend game."
				$viewport/notification/accept_decline.visible      = true
				$viewport/notification/reload.visible              = false
				$viewport/notification/accept_decline/accept.text  = "Confirm"
				$viewport/notification/accept_decline/decline.text = "Cancel"

	elif (len(notification_current.keys()) >= 1 && notification_current.type == NotificationType.JoinRequest):
		if ($viewport/notification/progress/timer.is_stopped()):
			if (Input.is_action_just_pressed("multiplayer_accept_join_request")):
				$viewport/notification/progress/timer.start()
				$viewport/notification/timeout.stop()
			else:
				$viewport/notification/progress/bar.anchor_right = move_toward($viewport/notification/progress/bar.anchor_right, 0.0, abs($viewport/notification/progress/bar.anchor_right) * delta * 25.0)
		else:
			if (Input.is_action_just_released("multiplayer_accept_join_request")):
				$viewport/notification/progress/timer.stop()
				$viewport/notification/timeout.start()
			else:
				$viewport/notification/progress/bar.anchor_right = 1.0 - $viewport/notification/progress/timer.time_left / $viewport/notification/progress/timer.wait_time





func update_activity() -> void:
	if (discord_active):
		var activity = S_GodotcordActivity.new()
		activity.details = get_activity_details(game_state)
		activity.state   = get_activity_state(game_state)
		match (game_state):
			GameState.Menu:
				pass
			GameState.GameHost:
				if (is_network_connected()):
					activity.party_id      = str(get_tree().network_peer.get_lobby_id())
					activity.join_secret   = get_tree().network_peer.get_lobby_activity_secret()
					activity.party_current = get_tree().network_peer.get_current_members()
					activity.party_max     = get_tree().network_peer.get_max_members()
			GameState.GameClient:
				if (is_network_connected()):
					activity.party_current = get_tree().network_peer.get_current_members()
					activity.party_max     = get_tree().network_peer.get_max_members()
		activity.start       = start
		activity.large_image = "spore"

		S_GodotcordActivityManager.set_activity(activity)


func get_activity_details(state : int) -> String:
	match (state):
		GameState.Menu       : return "Menu"
		GameState.GameHost   : return "In Game"
		GameState.GameClient : return "In Game"
	return ""


func get_activity_state(state : int) -> String:
	match (state):
		GameState.Menu       : return ""
		GameState.GameHost   :
			if (is_network_connected()):
				if (discord_active && get_tree().network_peer.get_current_members() > 1):
					return "Multiplayer"
				else:
					return "Singleplayer"
			else:
				return "Loading"
		GameState.GameClient:
			if (is_network_connected()):
				return "Multiplayer"
			else:
				return "Loading"
	return ""


func _exit_tree() -> void:
	if (discord_active):
		if (is_network_connected()):
			network_peer.close_connection()
		S_GodotcordActivityManager.clear_activity()





# Somebody has asked if they could join my game.
func join_request_received(user_name : String, user_id : int) -> void:
	if (game_state == GameState.GameHost):
		S_GodotcordUserManager.get_user(user_id)
		var user = yield(S_GodotcordUserManager, "get_user_callback")
		notification_queue.append({
			type               = NotificationType.JoinRequest,
			user_id            = user_id,
			user_name          = user_name,
			user_discriminator = user.discriminator
		})


# I clicked a join button in discord.
func join_pressed_in_discord(activity_secret : String) -> void:
	notification_queue.append({
		type   = NotificationType.Join,
		secret = activity_secret
	})



func notification_accept() -> void:
	match (notification_current.type):
		NotificationType.JoinRequest:
			S_GodotcordActivityManager.send_request_reply(notification_current.user_id, S_GodotcordActivity.YES)
		NotificationType.Invite:
			set_game_state(GameState.GameClient, notification_current.secret)
		NotificationType.Join:
			set_game_state(GameState.GameClient, notification_current.secret)
	notification_current = {}
	$viewport/notification/toggle.play_backwards("main")
	$viewport/notification/progress/timer.stop()
	$viewport/notification/timeout.stop()


func notification_decline() -> void:
	match (notification_current.type):
		NotificationType.JoinRequest:
			S_GodotcordActivityManager.send_request_reply(notification_current.user_id, S_GodotcordActivity.IGNORE)
	notification_current = {}
	$viewport/notification/toggle.play_backwards("main")
	$viewport/notification/progress/timer.stop()
	$viewport/notification/timeout.stop()


func notification_reload() -> void:
	get_tree().quit(0)


func notification_dismiss() -> void:
	notification_current = {}
	$viewport/notification/toggle.play_backwards("main")
	$viewport/notification/progress/timer.stop()
	$viewport/notification/timeout.stop()





func is_network_connected() -> bool:
	return (
		get_tree().network_peer &&
		get_tree().network_peer.get_connection_status() == get_tree().network_peer.CONNECTION_CONNECTED
	)


func is_sender_server() -> bool:
	return (! is_network_connected()) || get_tree().get_rpc_sender_id() in [SERVER_ID, 0]


func is_server() -> bool:
	return (! is_network_connected()) || get_tree().is_network_server()


func is_host() -> bool:
	return game_state == GameState.GameHost && discord_active
