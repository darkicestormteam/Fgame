extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Вызываем метод получения урона у игрока
		body.take_damage()
