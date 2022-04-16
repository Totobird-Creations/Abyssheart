extends Control



const USER_BUTTON           : PackedScene = preload("res://main/game/interface/user_button.tscn")

var   camera_pivot_position : float       = 0.0

var   thread                : Thread




func _ready() -> void:
	DiscordLink.set_game_state(DiscordLink.GameState.Menu)



# Main

func main_play() -> void:
	$menu/main/toggle.play_backwards("main")
	$menu/play/toggle.play("main")
	camera_pivot_position = $background/viewport/background/camera_pivot/loop.current_animation_position
	$background/viewport/background/camera_pivot/loop.stop()
	$background/viewport/background/camera_pivot/camera_vertical_offset/camera_distance_offset/transition.play("main_to_play")


func main_options() -> void:
	pass


func main_quit() -> void:
	$menu/quit/toggle.play("main")


# Play

func play_open() -> void:
	DiscordLink.next_game_state = DiscordLink.GameState.GameHost
	get_tree().change_scene("res://main/game/world.tscn")


#func play_join() -> void:
#	$menu/play/toggle.play_backwards("main")
#	$menu/join/toggle.play("main")
#	# Clear friends.
#	for child in $menu/join/top_bottom/top/vertical.get_children():
#		child.queue_free()
#	# Get friends.
#	GodotcordRelationshipManager.filter_relationships(self, "_relationship_filter")
#	var relationships := GodotcordRelationshipManager.get_relationships()
#	for relationship in relationships:
#		var instance     := USER_BUTTON.instance()
#		instance.mode     = instance.Mode.Join
#		instance.user_id  = relationship.user_id
#		$menu/join/top_bottom/top/vertical.add_child(instance)
#	# Play animations.
#	$menu/play/toggle.play_backwards("main")
#	$menu/join/toggle.play("main")
#	# Thread data
#	if (thread):
#		thread.wait_to_finish()
#	thread = Thread.new()
#	thread.start(self, "set_invite_list_data")
#
#func _relationship_filter(relationship : GodotcordRelationship) -> bool:
#	return (
#		relationship.type == GodotcordRelationship.FRIEND &&
#		relationship.presence.activity &&
#		relationship.presence.activity.application_id == DiscordLink.APPLICATION_ID &&
#		relationship.presence.activity.details == DiscordLink.get_details(DiscordLink.GameState.Game)
#	)
#
#func set_invite_list_data(_data) -> void:
#	for child in $menu/join/top_bottom/top/vertical.get_children():
#		if (! child.is_queued_for_deletion()):
#			GodotcordUserManager.get_user(child.user_id)
#			var user : GodotcordUser = yield(GodotcordUserManager, "get_user_callback")
#			child.set_name(user.name)
#			child.set_discriminator(int(user.discriminator))
#			child.set_avatar(user.avatar)
#			child.connect("user_pressed", self, "request_join")
#			child.disabled = false
#
#func request_join(user_id : int) -> void:
#	# Idk how to request to join somebody's game
#	pass


func play_back() -> void:
	$menu/play/toggle.play_backwards("main")
	$menu/main/toggle.play("main")
	$background/viewport/background/camera_pivot/loop.play("main")
	$background/viewport/background/camera_pivot/loop.seek(camera_pivot_position)
	$background/viewport/background/camera_pivot/camera_vertical_offset/camera_distance_offset/transition.play_backwards("main_to_play")


# Join

func join_user(_user_id : int) -> void:
	pass


func join_back() -> void:
	$menu/play/toggle.play("main")
	$menu/join/toggle.play_backwards("main")


# Quit

func quit_cancel() -> void:
	$menu/quit/toggle.play_backwards("main")


func quit_quit() -> void:
	get_tree().quit(0)
