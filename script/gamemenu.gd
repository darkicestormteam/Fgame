extends Control

# Переменные для хранения состояния громкости
var sfx_muted := false
var music_muted := false
var sfx_volume_db := 0.0
var music_volume_db := 0.0

# Переменные для отслеживания состояния настроек
var settings2_was_open := false # Был ли открыт MarginContainer2 (настройки) до нажатия settings1

# Переменные для хранения путей к сценам
var game_scene := "res://scenes/game.tscn"
var settings_scene := "res://scenes/settings.tscn" # Если сцены настроек нет, можно удалить или изменить

# Ссылки на узлы
@onready var sound1_button: TextureButton = $MarginContainer3/HBoxContainer/sound1
@onready var music1_button: TextureButton = $MarginContainer3/HBoxContainer/music1
@onready var settings1_button: TextureButton = $MarginContainer3/HBoxContainer/settings1
@onready var settings_container: MarginContainer = $MarginContainer
@onready var settings2_container: MarginContainer = $MarginContainer2 # Контейнер настроек (MarginContainer2)
@onready var sound_mute_sprite: Sprite2D = $MarginContainer3/HBoxContainer/sound1/Sprite2D
@onready var music_mute_sprite: Sprite2D = $MarginContainer3/HBoxContainer/music1/Sprite2D2
@onready var full_screen_toggle = $MarginContainer2/VBoxContainer/FullScreen

func _ready() -> void:
	# Устанавливаем режим обработки чтобы игнорировать паузу
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Сохраняем текущие уровни громкости
	sfx_volume_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	music_volume_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("music"))
	
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
	
	# Подключаем сигналы кнопок sound1, music1, settings1
	sound1_button.pressed.connect(_on_sound1_pressed)
	music1_button.pressed.connect(_on_music1_pressed)
	settings1_button.pressed.connect(_on_settings1_pressed)


func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Снимаем игру с паузы (если она была на паузе)
	get_tree().paused = false
	# Сбрасываем флаг состояния настроек
	settings2_was_open = false
	# Скрываем все контейнеры меню
	$MarginContainer.visible = false
	$MarginContainer2.visible = false


func _on_exit_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Ждем 1.0 секунды и закрываем игру
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


func _on_settings_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Запоминаем, что настройки были открыты
	settings2_was_open = true
	# Скрываем главное меню и показываем настройки
	$MarginContainer.visible = false
	$MarginContainer2.visible = true


func _on_back_pressed() -> void:
	# Воспроизводим звук Tap
	$Tap.play()
	# Сбрасываем флаг, так как мы вышли из настроек обратно в главное меню паузы
	settings2_was_open = false
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


func _on_sound1_pressed() -> void:
	var sfx_bus_index := AudioServer.get_bus_index("SFX")
	
	if sfx_muted:
		# Включаем звук - восстанавливаем предыдущую громкость
		AudioServer.set_bus_volume_db(sfx_bus_index, sfx_volume_db)
		sound_mute_sprite.visible = false
		sfx_muted = false
	else:
		# Выключаем звук - сохраняем текущую громкость и ставим -80dB
		sfx_volume_db = AudioServer.get_bus_volume_db(sfx_bus_index)
		AudioServer.set_bus_volume_db(sfx_bus_index, -80.0)
		sound_mute_sprite.visible = true
		sfx_muted = true


func _on_music1_pressed() -> void:
	var music_bus_index := AudioServer.get_bus_index("music")
	
	if music_muted:
		# Включаем музыку - восстанавливаем предыдущую громкость
		AudioServer.set_bus_volume_db(music_bus_index, music_volume_db)
		music_mute_sprite.visible = false
		music_muted = false
	else:
		# Выключаем музыку - сохраняем текущую громкость и ставим -80dB
		music_volume_db = AudioServer.get_bus_volume_db(music_bus_index)
		AudioServer.set_bus_volume_db(music_bus_index, -80.0)
		music_mute_sprite.visible = true
		music_muted = true


func _on_settings1_pressed() -> void:
	if get_tree().paused:
		# Снимаем с паузы
		get_tree().paused = false
		
		# Если настройки (MarginContainer2) были открыты, скрываем их и сбрасываем флаг
		if settings2_was_open:
			$MarginContainer2.visible = false
			settings2_was_open = false
		
		# Скрываем контейнер меню паузы
		settings_container.visible = false
	else:
		# Ставим на паузу
		get_tree().paused = true
		# Показываем контейнер меню паузы
		settings_container.visible = true
