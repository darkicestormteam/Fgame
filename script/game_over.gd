extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_language()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_reset_game_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	GameOver.hide()


func _apply_language() -> void:
	# Получаем узел локализации
	var localization = get_node_or_null("/root/Localization")
	if not localization:
		return
	
	# Обновляем текстовые элементы
	_update_label_text($Label, "game_over")
	_update_button_text($ResetGame, "btn_reset")


func _update_label_text(label: Label, key: String) -> void:
	if label:
		label.text = localization.get_text(key)


func _update_button_text(button: Button, key: String) -> void:
	if button:
		button.text = localization.get_text(key)
