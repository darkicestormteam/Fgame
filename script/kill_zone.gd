extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Ставим игру на паузу
		get_tree().paused = true
		# Находим узел GameOver и делаем его видимым
		var game_over = get_tree().get_first_node_in_group("game_over")
		if game_over == null:
			game_over = get_parent().get_node_or_null("GameOver")
		if game_over:
			game_over.visible = true
