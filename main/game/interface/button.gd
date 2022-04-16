extends Button



export(String) var disabled_text : String = ""

var backup_text : String



func hover() -> void:
	if (disabled && disabled_text != ""):
		backup_text = text
		text = disabled_text


func unhover() -> void:
	if (disabled && disabled_text != ""):
		text = backup_text
