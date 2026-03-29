extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.queue_free()
		get_tree().paused = true
		var game_over = get_node_or_null("/root/game/GameOver")
		if game_over:
			game_over.visible = true
