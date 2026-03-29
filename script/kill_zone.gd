extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.queue_free()
		get_tree().paused = true
		var game_over_node = get_tree().current_scene.get_node("GameOver")
		if game_over_node:
			game_over_node.visible = true
