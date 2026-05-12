extends Node

@export var key: String = ""

func _ready() -> void:
	update_text()

func update_text() -> void:
	if key != "":
		var translated_text = Localization.get_text(key)
		if self is Button:
			self.text = translated_text
		elif self is Label:
			self.text = translated_text
		elif self is CheckButton:
			self.text = translated_text
