extends Area2D


func _on_body_entered(body: Node2D) -> void:
	print("KillZone: body_entered called with: ", body.name)
	if body.name == "Player":
		print("Player detected, calling take_damage()")
		# Вызываем метод получения урона у игрока
		body.take_damage()
