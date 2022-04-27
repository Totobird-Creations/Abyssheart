extends StaticBody



func _physics_process(_delta : float) -> void:
	if ($floor_rotator.enabled):
		if ($floor_rotator.get_collider()):
			rotation += $floor_rotator.get_collision_normal() / 2.0
			$floor_rotator.enabled = false
