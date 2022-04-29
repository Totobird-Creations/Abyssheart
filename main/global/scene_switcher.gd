extends CanvasLayer



var target  : String
var is_boot : bool   = true



func switch_scene(goto : String) -> void:
	target = goto
	$viewport/fade/animation.play("main")


func _switch_scene_now() -> void:
	if (is_boot):
		DiscordLink.start()
		is_boot = false
	get_tree().change_scene(target)
