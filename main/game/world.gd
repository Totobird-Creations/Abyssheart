extends Spatial



const SERVER      : PackedScene = preload("res://main/game/multiplayer/server.tscn")
const HOSTER      : PackedScene = preload("res://main/game/multiplayer/hoster.tscn")
const CLIENT      : PackedScene = preload("res://main/game/multiplayer/client.tscn")

var   entities    : Dictionary  = {}





func get_game_interface() -> CanvasLayer:
	return $interface as CanvasLayer


func get_entity_object(id : int) -> KinematicBody:
	return $entities.get_node_or_null(str(id)) as KinematicBody


func get_next_entity_id() -> int:
	var id : int = 0
	while (entities.has(id)):
		id += 1
	return id





func _ready() -> void:
	match (DiscordLink.game_state):

		DiscordLink.GameState.GameHost:
			$service.add_child(SERVER.instance())
			if (DiscordLink.discord_active):
				var hoster := HOSTER.instance()
				$service.add_child(hoster)

		DiscordLink.GameState.GameClient:
			$service.add_child(CLIENT.instance())





remotesync func r_load_entity(entity_id : int, path : String, peer_id : int = 0) -> void:
	if (DiscordLink.is_sender_server()):
		load_entity(entity_id, path, peer_id)


func load_entity(entity_id : int, path : String, peer_id : int = 0) -> void:
	var entity  := load(path).instance() as Entity
	entity.name  = str(entity_id)
	entity.id    = entity_id
	if (entity is PlayerEntity):
		entity.peer_id  = peer_id
	entities[entity_id] = entity
	$entities.add_child(entity)


remotesync func r_update_entity(entity_id : int, data : Dictionary) -> void:
	if (DiscordLink.is_sender_server()):
		update_entity(entity_id, data)
	elif (DiscordLink.is_server()):
		for entity_id in entities.keys():
			var entity := entities[entity_id] as Entity
			if (entity.peer_id == get_tree().get_rpc_sender_id()):

				var filtered_data := data
				if (data.has( "pitch"        )): filtered_data.input_pitch  = data.pitch
				if (data.has( "yaw"          )): filtered_data.input_yaw    = data.yaw
				if (data.has( "input_vector" )): filtered_data.input_vector = data.input_vector
				if (data.has( "input_jump"   )): filtered_data.input_jump   = data.input_jump
				if (data.has( "input_sprint" )): filtered_data.input_sprint = data.input_sprint
				update_entity(entity.id, filtered_data)


func update_entity(entity_id : int, data : Dictionary) -> void:
	if (entities.has(entity_id)):
		var entity := entities[entity_id] as Entity
		entity.load_data(data)


remotesync func r_unload_entity(entity_id : int) -> void:
	if (DiscordLink.is_sender_server()):
		unload_entity(entity_id)


func unload_entity(entity_id : int) -> void:
	var entity := entities[entity_id] as Entity
	$entities.remove_child(entity)
	entity.queue_free()
	entities.erase(entity_id)
