extends Node



func _ready() -> void:
	if (! DiscordLink.is_host()):
		var world := get_game_world()
		var id    := 1
		world.r_load_entity(id, DiscordLink.PATH_PLAYER, id)
		world.r_update_entity(id, {
			controlling = true,
			translation = Vector3(0.0, 32.0, 0.0)
		})





func get_game_world() -> Spatial:
	return get_parent().get_parent() as Spatial
