extends Control

# Переменные для хранения состояния громкости
var sfx_muted := false
var music_muted := false
var sfx_volume_db := 0.0
var music_volume_db := 0.0

# Ссылки на узлы
@onready var sound1_button: TextureButton = $MarginContainer3/HBoxContainer/sound1
@onready var music1_button: TextureButton = $MarginContainer3/HBoxContainer/music1
@onready var settings1_button: TextureButton = $MarginContainer3/HBoxContainer/settings1
@onready var settings_container: MarginContainer = $MarginContainer
@onready var sound_mute_sprite: Sprite2D = $MarginContainer3/HBoxContainer/sound1/Sprite2D
@onready var music_mute_sprite: Sprite2D = $MarginContainer3/HBoxContainer/music1/Sprite2D2

func _ready() -> void:
	# Устанавливаем режим обработки чтобы игнорировать паузу
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Сохраняем текущие уровни громкости
	sfx_volume_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	music_volume_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("music"))
	
	# Подключаем сигналы кнопок
	sound1_button.pressed.connect(_on_sound1_pressed)
	music1_button.pressed.connect(_on_music1_pressed)
	settings1_button.pressed.connect(_on_settings1_pressed)


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
		# Снимаем с паузы и скрываем настройки
		get_tree().paused = false
		settings_container.visible = false
	else:
		# Ставим на паузу и показываем настройки
		get_tree().paused = true
		settings_container.visible = true
