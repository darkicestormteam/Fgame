extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_reset_game_pressed() -> void:
	# Сначала скрываем окно Game Over
	visible = false
	# Снимаем паузу
	get_tree().paused = false
	# Получаем путь к основной игровой сцене и загружаем её
	var main_scene_path = "res://scenes/game.tscn"
	get_tree().change_scene_to_file(main_scene_path)
