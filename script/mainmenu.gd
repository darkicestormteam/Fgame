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
	# Подключаем сигналы кнопок выбора языка
	$MarginContainer2/VBoxContainer/HBoxContainer3/Eng.pressed.connect(_on_eng_pressed)
	$MarginContainer2/VBoxContainer/HBoxContainer3/Rus.pressed.connect(_on_rus_pressed)
	# Применяем текущий язык при запуске
	_apply_language()


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
	var localization = get_node_or_null("/root/Localization")
	if localization:
		localization.set_locale("en")
	_apply_language()


func _on_rus_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Устанавливаем русский язык
	var localization = get_node_or_null("/root/Localization")
	if localization:
		localization.set_locale("ru")
	_apply_language()


func _apply_language() -> void:
	# Получаем узел локализации
	var localization = get_node_or_null("/root/Localization")
	if not localization:
		return
	
	var locale = localization.get_locale()
	
	# Обновляем все текстовые элементы в главном меню
	_update_label_text($MarginContainer/VBoxContainer/Start/Label, "btn_start")
	_update_label_text($MarginContainer/VBoxContainer/Settings/Label, "btn_settings")
	_update_label_text($MarginContainer/VBoxContainer/Exit/Label, "btn_exit")
	_update_label_text($MarginContainer2/VBoxContainer/Label, "lbl_volume")
	_update_label_text($MarginContainer2/VBoxContainer/HBoxContainer/Label, "lbl_music")
	_update_label_text($MarginContainer2/VBoxContainer/HBoxContainer2/Label, "lbl_sfx")
	_update_label_text($MarginContainer2/VBoxContainer/Back/Label, "btn_back")
	_update_label_text($MarginContainer2/VBoxContainer/HBoxContainer3/Eng/Label, "btn_eng")
	_update_label_text($MarginContainer2/VBoxContainer/HBoxContainer3/Rus/Label, "btn_rus")


func _update_label_text(label: Label, key: String) -> void:
	if label:
		label.text = localization.get_text(key)
