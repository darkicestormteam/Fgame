extends Label

@export var key: String = ""

func _ready() -> void:
	update_text()

func update_text() -> void:
	if key != "":
		text = Localization.get_text(key)
