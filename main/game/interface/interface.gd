extends CanvasLayer



enum MouseMode {
	Game,
	Pause,
	Invite
}

const USER_BUTTON : PackedScene = preload("res://main/game/interface/user_button.tscn")

var   mouse_mode  : int    = MouseMode.Game setget set_mouse_mode
var   thread      : Thread





func set_mouse_mode(value : int) -> void:
	# Clean up previous state
	match (mouse_mode):
		MouseMode.Pause:
			$pause/toggle.play_backwards("main")
		MouseMode.Invite:
			$invite/toggle.play_backwards("main")
	# Set new state
	mouse_mode = value
	# Set up new state
	match (mouse_mode):
		MouseMode.Game:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		MouseMode.Pause:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$pause/toggle.play("main")
		MouseMode.Invite:
			$invite/toggle.play("main")





func _ready() -> void:
	set_mouse_mode(MouseMode.Game)
	$pause/align/top_bottom/top/invite.disabled = false
	if (! DiscordLink.discord_active):
		$pause/align/top_bottom/top/invite.disabled = true
		$pause/align/top_bottom/top/invite.disabled_text = "Multiplayer Disabled"
	elif (DiscordLink.game_state != DiscordLink.GameState.GameHost):
		$pause/align/top_bottom/top/invite.disabled = true
		$pause/align/top_bottom/top/invite.disabled_text = "Unowned Lobby"


func _process(_delta : float) -> void:
	if (Input.is_action_just_pressed("interface_back")):
		match (mouse_mode):
			MouseMode.Game:
				set_mouse_mode(MouseMode.Pause)
			MouseMode.Pause:
				set_mouse_mode(MouseMode.Game)
			MouseMode.Invite:
				set_mouse_mode(MouseMode.Pause)


func _exit_tree() -> void:
	if (thread):
		thread.wait_to_finish()





# Pause.

func pause_back() -> void:
	set_mouse_mode(MouseMode.Game)


func pause_invite() -> void:
	set_mouse_mode(MouseMode.Invite)
	# Clear friends.
	for child in $invite/align/top_bottom/top/vertical.get_children():
		child.queue_free()
	# Get friends.
	GodotcordRelationshipManager.filter_relationships(self, "_relationship_filter")
	var relationships = GodotcordRelationshipManager.get_relationships()
	for relationship in relationships:
		var instance     := USER_BUTTON.instance()
		instance.mode     = instance.Mode.Invite
		instance.user_id  = relationship.user_id
		$invite/align/top_bottom/top/vertical.add_child(instance)
	# Thread data
	if (thread):
		thread.wait_to_finish()
	thread = Thread.new()
	thread.start(self, "set_invite_list_data")

func _relationship_filter(relationship) -> bool:
	return relationship.type == GodotcordRelationship.FRIEND

func set_invite_list_data(_data) -> void:
	for child in $invite/align/top_bottom/top/vertical.get_children():
		if (! child.is_queued_for_deletion()):
			GodotcordUserManager.get_user(child.user_id)
			var user = yield(GodotcordUserManager, "get_user_callback")
			child.set_name(user.name)
			child.set_discriminator(int(user.discriminator))
			child.set_avatar(user.avatar)
			child.connect("user_pressed", self, "invite_user")
			child.disabled = false


func pause_menu() -> void:
	SceneSwitcher.switch_scene("res://main/menu/main.tscn")


# Invite.

func invite_user(user_id : int) -> void:
	GodotcordActivityManager.send_invite(user_id, GodotcordActivity.JOIN, "")


func invite_cancel() -> void:
	set_mouse_mode(MouseMode.Pause)
