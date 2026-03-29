extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.queue_free()
		get_tree().paused = true
		get_node("/root/GameOver").visible = true
