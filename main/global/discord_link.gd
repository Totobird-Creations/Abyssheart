extends Node



const APPLICATION_ID     : int        = 962773221130797126

const ICON_RELOAD        : Texture    = preload("res://assets/texture/interface/icon/reload.png")

var   discord_active     : bool       = false

enum NotificationType {
	DiscordInactive,
	JoinRequest,
	Invite,
	Join
}

enum GameState {
	Menu,
	GameSingle,
	GameHost,
	GameClient
}
var game_state           : int        = GameState.Menu setget set_game_state
var next_game_state      : int
var start                : int        = OS.get_unix_time()

var notification_queue   : Array      = []
var notification_current : Dictionary = {}

var is_hosting           : bool       = false
var join_secret          : String





func set_game_state(value : int) -> void:
	if (value != game_state):
		match (game_state):

			GameState.Menu:
				var new_notification_queue := []
				for notification in notification_queue:
					if (notification.type != NotificationType.DiscordInactive):
						new_notification_queue.append(notification)
				notification_queue = new_notification_queue
				if (len(notification_current.keys()) >= 1 && notification_current.type == NotificationType.DiscordInactive):
					notification_dismiss()

			GameState.GameHost:
				var new_notification_queue := []
				for notification in notification_queue:
					if (notification.type != NotificationType.JoinRequest):
						new_notification_queue.append(notification)
				notification_queue = new_notification_queue
				if (len(notification_current.keys()) >= 1 && notification_current.type == NotificationType.JoinRequest):
					notification_decline()

		game_state = value

	update_activity()


func get_activity_details(state : int) -> String:
	match (state):
		GameState.Menu       : return "Menu"
		GameState.GameSingle : return "In Game"
		GameState.GameHost   : return "In Game"
		GameState.GameClient : return "In Game"
	return ""


func get_activity_state(state : int) -> String:
	match (state):
		GameState.Menu       : return ""
		GameState.GameSingle : return "Singleplayer"
		GameState.GameHost   :
			if (get_tree().network_peer.get_current_members() > 1):
				return "Multiplayer"
			else:
				return "Singleplayer"
		GameState.GameClient : return "Multiplayer"
	return ""





func _ready() -> void:
	var error : int = Godotcord.init(APPLICATION_ID, Godotcord.CreateFlags_NO_REQUIRE_DISCORD)
	if (error == OK):
		discord_active = true
		update_activity()

		GodotcordActivityManager.connect("activity_join_request", self, "join_request_received")
		GodotcordActivityManager.connect("activity_join", self, "join_pressed_in_discord")
	else:
		discord_active = false
		notification_queue.append({
			type = NotificationType.DiscordInactive,
		})



func _process(delta : float) -> void:
	Godotcord.run_callbacks()

	if (len(notification_current.keys()) <= 0 && len(notification_queue) >= 1):
		notification_current = notification_queue[0]
		notification_queue.remove(0)
		$viewport/notification/progress/bar.anchor_right = 0.0
		$viewport/notification/toggle.play("main")
		$viewport/notification/timeout.start()
		match (notification_current.type):
			NotificationType.DiscordInactive:
				$viewport/notification/message.text           = "Failed to connect to Discord. Multiplayer is disabled."
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
		var activity : GodotcordActivity = GodotcordActivity.new()
		activity.details = get_activity_details(game_state)
		activity.state   = get_activity_state(game_state)
		match (game_state):
			GameState.Menu:
				pass
			GameState.GameHost:
				assert(get_tree().network_peer.get_connection_status() == get_tree().network_peer.CONNECTION_CONNECTED)
				print(get_tree().network_peer.get_lobby_id(), " ", get_tree().network_peer.get_lobby_secret())
				activity.party_id      = str(get_tree().network_peer.get_lobby_id())
				activity.join_secret   = get_tree().network_peer.get_lobby_secret()
				activity.party_current = get_tree().network_peer.get_current_members()
				activity.party_max     = get_tree().network_peer.get_max_members()
			GameState.GameClient:
				activity.party_current = get_tree().network_peer.get_current_members()
				activity.party_max     = get_tree().network_peer.get_max_members()
		activity.start       = start
		activity.large_image = "spore"

		GodotcordActivityManager.set_activity(activity)


func _exit_tree() -> void:
	if (discord_active):
		GodotcordActivityManager.clear_activity()





# Somebody has asked if they could join my game.
func join_request_received(user_name : String, user_id : int) -> void:
	if (game_state == GameState.GameHost):
		GodotcordUserManager.get_user(user_id)
		var user : GodotcordUser = yield(GodotcordUserManager, "get_user_callback")
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
			GodotcordActivityManager.send_request_reply(notification_current.user_id, GodotcordActivity.YES)
		NotificationType.Invite:
			join_lobby(notification_current.secret)
		NotificationType.Join:
			join_lobby(notification_current.secret)
	notification_current = {}
	$viewport/notification/toggle.play_backwards("main")
	$viewport/notification/progress/timer.stop()
	$viewport/notification/timeout.stop()

func notification_decline() -> void:
	match (notification_current.type):
		NotificationType.JoinRequest:
			GodotcordActivityManager.send_request_reply(notification_current.user_id, GodotcordActivity.IGNORE)
	notification_current = {}
	$viewport/notification/toggle.play_backwards("main")
	$viewport/notification/progress/timer.stop()
	$viewport/notification/timeout.stop()

func notification_dismiss() -> void:
	notification_current = {}
	$viewport/notification/toggle.play_backwards("main")
	$viewport/notification/progress/timer.stop()
	$viewport/notification/timeout.stop()

func notification_reload() -> void:
	get_tree().quit(0)



func join_lobby(secret : String) -> void:
	next_game_state = GameState.GameClient
	join_secret = secret
	get_tree().change_scene("res://main/game/world.tscn")
