extends Area2D


func _on_body_entered(body: Node2D) -> void:
	print("KillZone: body_entered triggered with body: ", body.name)
	if body.name == "Player":
		print("KillZone: Player detected, pausing game and showing GameOver")
		# Ставим игру на паузу
		get_tree().paused = true
		# Находим узел GameOver в сцене через глобальный поиск и делаем его видимым
		var game_over = get_tree().get_first_node_in_group("game_over")
		if not game_over:
			game_over = get_node("/root/game/GameOver")
		if not game_over:
			game_over = get_tree().current_scene.get_node_or_null("GameOver")
		
		if game_over:
			print("KillZone: GameOver found, setting visible=true")
			game_over.visible = true
		else:
			print("KillZone: GameOver NOT found! Current scene: ", get_tree().current_scene.name)
			# Выводим все узлы текущей сцены для отладки
			for child in get_tree().current_scene.get_children():
				print("  Child: ", child.name)
