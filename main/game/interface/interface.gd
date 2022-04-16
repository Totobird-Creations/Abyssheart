extends CanvasLayer



const USER_BUTTON : PackedScene = preload("res://main/game/interface/user_button.tscn")

var   thread      : Thread



func _ready() -> void:
	$pause/align/top_bottom/top/invite.disabled = ! DiscordLink.discord_active
	if (! DiscordLink.discord_active):
		$pause/align/top_bottom/top/invite.disabled_text = "Multiplayer Disabled"
	elif (DiscordLink.game_state == DiscordLink.GameState.GameClient):
		$pause/align/top_bottom/top/invite.disabled_text = "Unowned Lobby"



# Pause.

func pause_back() -> void:
	$pause/toggle.play_backwards("main")


func pause_invite() -> void:
	# Clear friends.
	for child in $invite/align/top_bottom/top/vertical.get_children():
		child.queue_free()
	# Get friends.
	GodotcordRelationshipManager.filter_relationships(self, "_relationship_filter")
	var relationships := GodotcordRelationshipManager.get_relationships()
	for relationship in relationships:
		var instance     := USER_BUTTON.instance()
		instance.mode     = instance.Mode.Invite
		instance.user_id  = relationship.user_id
		$invite/align/top_bottom/top/vertical.add_child(instance)
	# Play animations.
	$pause/toggle.play_backwards("main")
	$invite/toggle.play("main")
	# Thread data
	if (thread):
		thread.wait_to_finish()
	thread = Thread.new()
	thread.start(self, "set_invite_list_data")

func _relationship_filter(relationship : GodotcordRelationship) -> bool:
	return relationship.type == GodotcordRelationship.FRIEND

func set_invite_list_data(_data) -> void:
	for child in $invite/align/top_bottom/top/vertical.get_children():
		if (! child.is_queued_for_deletion()):
			GodotcordUserManager.get_user(child.user_id)
			var user : GodotcordUser = yield(GodotcordUserManager, "get_user_callback")
			child.set_name(user.name)
			child.set_discriminator(int(user.discriminator))
			child.set_avatar(user.avatar)
			child.connect("user_pressed", self, "invite_user")
			child.disabled = false


func pause_menu() -> void:
	get_tree().change_scene("res://main/menu/main.tscn")


# Invite.

func invite_user(user_id : int) -> void:
	GodotcordActivityManager.send_invite(user_id, GodotcordActivity.JOIN, "")


func invite_cancel() -> void:
	$invite/toggle.play_backwards("main")
	$pause/toggle.play("main")





func _exit_tree() -> void:
	if (thread):
		thread.wait_to_finish()
