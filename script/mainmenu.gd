extends Control

# Переменные для хранения путей к сценам
var game_scene := "res://scenes/game.tscn"
var settings_scene := "res://scenes/settings.tscn" # Если сцены настроек нет, можно удалить или изменить

@onready var full_screen_toggle = $MarginContainer2/VBoxContainer/FullScreen


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Подключаем сигналы кнопок главного меню
	$MarginContainer/VBoxContainer/Start.pressed.connect(_on_start_pressed)
	$MarginContainer/VBoxContainer/Exit.pressed.connect(_on_exit_pressed)
	$MarginContainer/VBoxContainer/Settings.pressed.connect(_on_settings_pressed)
	# Подключаем сигнал кнопки Back в настройках
	$MarginContainer2/VBoxContainer/Back.pressed.connect(_on_back_pressed)
	# Подключаем сигналы кнопок выбора языка
	$MarginContainer2/VBoxContainer/HBoxContainer3/Eng.pressed.connect(_on_eng_pressed)
	$MarginContainer2/VBoxContainer/HBoxContainer3/Rus.pressed.connect(_on_rus_pressed)
	# Подключаем сигнал переключателя FullScreen
	if full_screen_toggle:
		full_screen_toggle.toggled.connect(_on_full_screen_toggled)
		# Устанавливаем начальное состояние переключателя
		var current_mode = DisplayServer.window_get_mode()
		full_screen_toggle.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN || current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


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


func _on_eng_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Устанавливаем английский язык
	Localization.set_locale("en")
	# Обновляем все тексты в главном меню и настройках
	_update_all_localized_texts()


func _on_rus_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Устанавливаем русский язык
	Localization.set_locale("ru")
	# Обновляем все тексты в главном меню и настройках
	_update_all_localized_texts()


func _update_all_localized_texts() -> void:
	# Рекурсивно находим все узлы с методом update_text
	_update_node_recursive(self)


func _update_node_recursive(node: Node) -> void:
	if node.has_method("update_text"):
		node.update_text()
	for child in node.get_children():
		_update_node_recursive(child)


func _on_full_screen_toggled(is_fullscreen: bool) -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
