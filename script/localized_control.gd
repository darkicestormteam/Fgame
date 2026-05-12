extends Node

@export var key: String = ""

func _ready() -> void:
	update_text()

func update_text() -> void:
	if key != "":
		var translated_text = Localization.get_text(key)
		var node = get_node(".") as Node
		
		if node is Button:
			(node as Button).text = translated_text
		elif node is Label:
			(node as Label).text = translated_text
		elif node is CheckButton:
			(node as CheckButton).text = translated_text
