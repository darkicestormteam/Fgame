extends Area2D


func _on_body_entered(body: Node2D) -> void:
	print("KillZone: body_entered triggered with body: ", body.name)
	if body.name == "Player":
		print("KillZone: Player detected, pausing game and showing GameOver")
		# Ставим игру на паузу
		get_tree().paused = true
		# Находим узел GameOver в сцене и делаем его видимым
		var game_over = get_parent().get_node_or_null("GameOver")
		if game_over:
			print("KillZone: GameOver found, setting visible=true")
			game_over.visible = true
		else:
			print("KillZone: GameOver NOT found in parent!")
