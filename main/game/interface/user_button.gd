extends Button



signal user_pressed(user_id)

export(String) var disabled_text : String = ""

enum Mode {
	Invite,
	Join
}
var mode               : int    = Mode.Invite
var user_id            : int
var user_name          : String
var user_discriminator : int
var user_avatar        : String

var backup_text        : String


func set_name(name : String) -> void:
	user_name = name
	text = user_name


func set_discriminator(discriminator : int) -> void:
	user_discriminator = discriminator
	$discriminator.text = "#" + str(user_discriminator).pad_zeros(4)


func set_avatar(avatar : String) -> void:
	user_avatar = avatar
	if (user_avatar == ""):
		$request.request("https://cdn.discordapp.com/embed/avatars/" + str(user_discriminator % 5) + ".png")
	else:
		$request.request("https://cdn.discordapp.com/avatars/" + str(user_id) + "/" + user_avatar + ".png")



func pressed() -> void:
	disabled = true
	match (mode):
		Mode.Invite : $complete/text.text = "Sent Invite"
		Mode.Join   : $complete/text.text = "Sent Join Request"
	$complete/toggle.play("main")
	emit_signal("user_pressed", user_id)



func image_downloaded(_result : int, _response_code : int, _headers : PoolStringArray, body : PoolByteArray) -> void:
	var image := Image.new()
	var error := image.load_png_from_buffer(body)
	if (error == OK):
		var texture := ImageTexture.new()
		texture.create_from_image(image, Texture.FLAG_MIPMAPS + Texture.FLAG_FILTER)
		$icon.self_modulate.a = 1.0
		$icon/loading.visible = false
		$icon.material.set_shader_param("icon", texture)
	else:
		print(user_avatar)



func hover() -> void:
	if (disabled && disabled_text != ""):
		backup_text = text
		text = disabled_text


func unhover() -> void:
	if (disabled && disabled_text != ""):
		text = backup_text
