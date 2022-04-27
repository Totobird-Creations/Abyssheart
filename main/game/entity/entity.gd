extends Spatial
class_name Entity



const             MAX_FLOOR_ANGLE       : float   = (PI / 2.0) * 0.625
const             GRAVITY               : float   = 40.0
const             AIR_CONTROL           : float   = 0.5

export(float) var jump_strength         : float   = 10.0
export(float) var walk_speed            : float   = 5.0
export(float) var sprint_speed          : float   = 10.0
export(float) var acceleration          : float   = 8.0
export(float) var deceleration          : float   = 10.0

var               id                    : int

var               velocity              : Vector3 = Vector3.ZERO
var               snap                  : Vector3 = Vector3.ZERO

var               input_vector          : Vector2 = Vector2.ZERO
var               input_jump            : bool    = false
var               input_sprint          : bool    = false





func get_rotation_pitch() -> Spatial:
	# Up & Down
	return null


func get_rotation_yaw() -> Spatial:
	# Side to Side
	return null


func get_body() -> KinematicBody:
	return null


func get_game_world() -> Spatial:
	return get_parent().get_parent() as Spatial


func get_game_interface() -> CanvasLayer:
	return get_game_world().get_game_interface() as CanvasLayer





func load_data(data : Dictionary) -> void:
	# Identifier
	id = data.get("id", id)

	# Position
	translation = data.get("translation", translation)
	if (! "FLAG_NO_LOAD_ROTATION" in self):
		var pitch := get_rotation_pitch()
		pitch.rotation.x = data.get("pitch", pitch.rotation.x)
		var yaw := get_rotation_pitch()
		yaw.rotation.y = data.get("yaw", pitch.rotation.y)

	# Motion
	velocity = data.get("velocity", velocity)
	snap     = data.get("snap", snap)

	# Input
	input_vector = data.get("input_vector", input_vector)
	input_jump   = data.get("input_jump", input_jump)
	input_sprint = data.get("input_sprint", input_sprint)


func generate_data(_sub : bool = true, data : Dictionary = {}) -> Dictionary:
	# Identifier
	data.id = id

	# Position
	data.translation  = translation
	data.pitch    = get_rotation_pitch().rotation.x
	data.yaw      = get_rotation_yaw().rotation.y

	# Motion
	data.velocity = velocity
	data.snap     = snap

	# Input
	data.input_vector = input_vector
	data.input_jump   = input_jump
	data.input_sprint = input_sprint

	# Response
	return data





func _physics_process(delta : float) -> void:
	# Input Direction
	var direction : Vector3 = Vector3.ZERO
	var aim       : Basis   = get_rotation_pitch().get_global_transform().basis
	if (input_vector.x >= 0.5):
		direction -= aim.z
	if (input_vector.x <= -0.5):
		direction += aim.z
	if (input_vector.y >= 0.5):
		direction += aim.x
	if (input_vector.y <= -0.5):
		direction -= aim.x
	direction.y = 0.0
	direction = direction.normalized()

	# Snapping
	if (get_body().is_on_floor()):
		snap = -get_body().get_floor_normal() - get_body().get_floor_velocity() * delta
		velocity.y = max(velocity.y, 0)

		# Jump
		if (input_jump):
			velocity.y = jump_strength
			snap = Vector3.ZERO

	else:
		if (snap != Vector3.ZERO && velocity.y != 0):
			velocity.y = 0
		snap = Vector3.ZERO
		velocity.y -= GRAVITY * delta

	# Walk / Sprint
	var speed : float = walk_speed
	if (get_body().is_on_floor() && input_sprint && input_vector.x >= 0.5):
		speed = sprint_speed

	# Acceleration
	var temp_velocity     : Vector3 = velocity
	var temp_acceleration : float
	var target            : Vector3 = direction * speed
	temp_velocity.y = 0.0
	if (direction.dot(temp_velocity) > 0):
		temp_acceleration = acceleration
	else:
		temp_acceleration = deceleration
	if (! get_body().is_on_floor()):
		temp_acceleration *= AIR_CONTROL
	temp_velocity = temp_velocity.linear_interpolate(target, temp_acceleration * delta)
	velocity.x = temp_velocity.x
	velocity.z = temp_velocity.z
	if (direction.dot(velocity) == 0):
		var velocity_clamp : float = 0.01
		if (abs(velocity.x) < velocity_clamp):
			velocity.x = 0
		if (abs(velocity.z) < velocity_clamp):
			velocity.z = 0

	# Move character
	velocity = get_body().move_and_slide_with_snap(velocity, snap, Vector3.UP, true, 4, MAX_FLOOR_ANGLE)

	# Reset impulse inputs
	input_jump = false

	if (DiscordLink.is_server()):
		get_game_world().rpc("r_update_entity", id, generate_data())
