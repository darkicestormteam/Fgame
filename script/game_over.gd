extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_reset_game_pressed() -> void:
	get_tree().paused = false
	# Используем GameManager для перезапуска
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("restart_game"):
		game_manager.restart_game()
	
	get_tree().reload_current_scene()
	# Исправляем ошибку: GameOver - это имя узла, а не класс
	if has_node("GameOver"):
		get_node("GameOver").visible = false
	elif visible:
		visible = false
