extends Control



var target_progress : float = 0.0



func start_load() -> void:
	target_progress = 1.0



func _physics_process(delta : float) -> void:
	if ($bar/bounds/progress.anchor_right >= 1.0):
		SceneSwitcher.switch_scene("res://main/menu/main.tscn")

	$bar/bounds/progress.anchor_right = move_toward(
		$bar/bounds/progress.anchor_right,
		target_progress,
		delta * 2.0
	)
