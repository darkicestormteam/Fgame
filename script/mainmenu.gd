extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Подключаем сигналы кнопок
	$MarginContainer/VBoxContainer/Start.pressed.connect(_on_start_pressed)
	$MarginContainer/VBoxContainer/Exit.pressed.connect(_on_exit_pressed)
	$MarginContainer/VBoxContainer/Settings.pressed.connect(_on_settings_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	# Загружаем и переключаемся на сцену игры
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_exit_pressed() -> void:
	# Закрываем игру
	get_tree().quit()


func _on_settings_pressed() -> void:
	# Здесь можно добавить логику для настроек
	pass
