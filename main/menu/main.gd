extends Control



var camera_pivot_position : float         = 0.0



func _ready() -> void:
	DiscordLink.set_game_state(DiscordLink.GameState.Menu)



# Main

func main_play() -> void:
	$menu/main/toggle.play_backwards("main")
	$menu/play/toggle.play("main")
	camera_pivot_position = $background/viewport/background/camera_pivot/loop.current_animation_position
	$background/viewport/background/camera_pivot/loop.stop()
	$background/viewport/background/camera_pivot/camera_vertical_offset/camera_distance_offset/transition.play("main_to_play")

func main_quit() -> void:
	$menu/quit/toggle.play("main")


# Play

func play_back() -> void:
	$menu/play/toggle.play_backwards("main")
	$menu/main/toggle.play("main")
	$background/viewport/background/camera_pivot/loop.play("main")
	$background/viewport/background/camera_pivot/loop.seek(camera_pivot_position)
	$background/viewport/background/camera_pivot/camera_vertical_offset/camera_distance_offset/transition.play_backwards("main_to_play")

func play_openworld() -> void:
	get_tree().change_scene("res://main/game/world.tscn")


# Quit

func quit_cancel() -> void:
	$menu/quit/toggle.play_backwards("main")


func quit_quit() -> void:
	get_tree().quit(0)
