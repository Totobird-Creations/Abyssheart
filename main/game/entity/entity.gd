extends RigidBody
class_name Entity



func load_data(data : Dictionary) -> void:
	translation      = data.translation
	linear_velocity  = data.linear_velocity
	angular_velocity = data.angular_velocity
