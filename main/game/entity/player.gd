extends Entity
class_name PlayerEntity



const FLAG_NO_LOAD_ROTATION := true



var               peer_id           : int

export(bool)  var controlling       : bool    = false
export(float) var mouse_sensitivity : float   = 0.002





func get_rotation_pitch() -> Spatial:
	# Up & Down
	return $body/pivot/camera as Spatial


func get_rotation_yaw() -> Spatial:
	# Side to Side
	return $body/pivot as Spatial


func get_body() -> KinematicBody:
	return $body as KinematicBody


func get_game_world() -> Spatial:
	return get_parent().get_parent() as Spatial





func load_data(data : Dictionary) -> void:
	.load_data(data)
	peer_id     = data.get("peer_id", peer_id)
	controlling = peer_id == get_tree().get_network_unique_id()
	if (controlling):
		$body/pivot/camera/camera.make_current()
	else:
		var pitch := get_rotation_pitch()
		pitch.rotation.x = data.get("pitch", pitch.rotation.x)
		var yaw := get_rotation_pitch()
		yaw.rotation.y = data.get("yaw", pitch.rotation.y)


func generate_data(sub : bool = true, data : Dictionary = {}) -> Dictionary:
	data.peer_id = peer_id
	if (sub):
		data = .generate_data(sub, data)
	return data





func _physics_process(_delta : float) -> void:
	if (controlling):
		input_vector = Vector2(
			Input.get_action_strength("player_move_forward") - Input.get_action_strength("player_move_backward"),
			Input.get_action_strength("player_move_right")   - Input.get_action_strength("player_move_left")
		)
		input_jump   = Input.is_action_just_pressed("player_move_jump")
		input_sprint = Input.is_action_pressed("player_move_sprint")

		if (! DiscordLink.is_server()):
			get_game_world().rpc("r_update_entity", id, generate_data(false))



func _input(event : InputEvent) -> void:
	if (controlling && get_game_interface().mouse_mode == get_game_interface().MouseMode.Game):
		# Rotate camera on mouse motion if controlling.
		if (event is InputEventMouseMotion):
			get_rotation_pitch().rotation.x = clamp(get_rotation_pitch().rotation.x - (event.relative.y * mouse_sensitivity), -PI / 2.0 + (PI / 32.0), PI / 2.0 - (PI / 32.0))
			get_rotation_yaw().rotation.y -= event.relative.x * mouse_sensitivity
