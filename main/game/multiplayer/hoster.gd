extends Node



var clients : Dictionary = {}





func _ready() -> void:
	DiscordLink.network_peer.connect("created_lobby", self, "created_lobby")
	DiscordLink.network_peer.connect("peer_connected", self, "client_connected")
	DiscordLink.network_peer.connect("peer_disconnected", self, "client_disconnected")


func _exit_tree() -> void:
	DiscordLink.network_peer.close_connection()
	get_tree().set_network_peer(null)





func created_lobby() -> void:
	DiscordLink.update_activity()
	client_connected(DiscordLink.SERVER_ID)
	#var id := get_next_entity_id()
	#load_entity(id, PATH_PLAYER)
	#update_entity(id, {
	#	controlling = true
	#})


func client_connected(peer_id : int) -> void:
	if (DiscordLink.is_server()):
		var user_id : int = DiscordLink.network_peer.get_user_id_by_peer(peer_id)
		GodotcordUserManager.get_user(user_id)
		var user : GodotcordUser = yield(GodotcordUserManager, "get_user_callback")
		Logger.network("Connected : " + str(user.name))

		var world := get_game_world()
		var id    := world.get_next_entity_id() as int
		world.rpc("r_load_entity", id, DiscordLink.PATH_PLAYER, peer_id)
		world.rpc("r_update_entity", id, {
			controlling = peer_id == get_tree().get_network_unique_id(),
			translation = Vector3(0.0, 32.0, 0.0)
		})
		for entity_id in world.entities:
			var entity := world.entities[entity_id] as Entity
			if (entity is PlayerEntity && entity.peer_id != peer_id):
				world.rpc_id(peer_id, "r_load_entity", entity_id, entity.filename)
				world.rpc_id(peer_id, "r_update_entity", entity_id, {})

		clients[peer_id] = {
			peer_id   = peer_id,
			user_id   = user_id,
			user      = user,
			entity_id = id
		}

		DiscordLink.update_activity()


func client_disconnected(peer_id : int) -> void:
	var client : Dictionary = clients[peer_id]
	Logger.network("Disconnected : " + str(client.user.name))

	get_game_world().unload_entity(client.entity_id)

	clients.erase(peer_id)

	DiscordLink.update_activity()





func get_game_world() -> Spatial:
	return get_parent().get_parent() as Spatial
