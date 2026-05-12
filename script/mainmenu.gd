extends Control

# Переменные для хранения путей к сценам
var game_scene := "res://scenes/game.tscn"
var settings_scene := "res://scenes/settings.tscn" # Если сцены настроек нет, можно удалить или изменить


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Подключаем сигналы кнопок главного меню
	$MarginContainer/VBoxContainer/Start.pressed.connect(_on_start_pressed)
	$MarginContainer/VBoxContainer/Exit.pressed.connect(_on_exit_pressed)
	$MarginContainer/VBoxContainer/Settings.pressed.connect(_on_settings_pressed)
	# Подключаем сигнал кнопки Back в настройках
	$MarginContainer2/VBoxContainer/Back.pressed.connect(_on_back_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Ждем 1.0 секунды и переключаемся на сцену игры
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(game_scene)


func _on_exit_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Ждем 1.0 секунды и закрываем игру
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


func _on_settings_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Скрываем главное меню и показываем настройки
	$MarginContainer.visible = false
	$MarginContainer2.visible = true


func _on_back_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Скрываем настройки и показываем главное меню
	$MarginContainer2.visible = false
	$MarginContainer.visible = true
