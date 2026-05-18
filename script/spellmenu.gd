extends CanvasLayer


var is_visible: bool = false
var is_active: bool = false # Флаг активности меню (открыто и ждет выбора)

# Переменные для хранения состояния громкости
var sfx_muted := false
var music_muted := false
var sfx_volume_db := 0.0
var music_volume_db := 0.0

# Переменная для отслеживания состояния настроек (открыты ли они)
var settings_open := false

@onready var tap_sound: AudioStreamPlayer = $Tap
@onready var spell_sheep_btn: TextureButton = $MarginContainer/HBoxContainer/SpellSheep
@onready var sword_up_btn: TextureButton = $MarginContainer/HBoxContainer/SwordUP
@onready var splash_btn: TextureButton = $MarginContainer/HBoxContainer/Splash

# Ссылки на подсказки
@onready var spell_sheep_tooltip: Label = $MarginContainer/HBoxContainer/SpellSheep/TooltipText
@onready var sword_up_tooltip: Label = $MarginContainer/HBoxContainer/SwordUP/TooltipText
@onready var splash_tooltip: Label = $MarginContainer/HBoxContainer/Splash/TooltipText

# Ссылки на контейнеры
@onready var margin_container2: MarginContainer = $MarginContainer2
@onready var margin_container3: MarginContainer = $MarginContainer3
@onready var margin_container4: MarginContainer = $MarginContainer4

# Ссылки на кнопки MarginContainer4
@onready var sound1_button: TextureButton = $MarginContainer4/HBoxContainer/sound1
@onready var music1_button: TextureButton = $MarginContainer4/HBoxContainer/music1
@onready var settings1_button: TextureButton = $MarginContainer4/HBoxContainer/settings1

# Ссылки на спрайты заглушки
@onready var sound_mute_sprite: Sprite2D = $MarginContainer4/HBoxContainer/sound1/Sprite2D
@onready var music_mute_sprite: Sprite2D = $MarginContainer4/HBoxContainer/music1/Sprite2D2

# Ссылка на SheepSpawner
var sheep_spawner: Node2D = null
# Ссылка на GameMenu
var game_menu: Control = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		# Скрываем меню при старте
		visible = false
		is_active = false
		
		# Инициализируем состояние громкости
		sfx_volume_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
		music_volume_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("music"))

		# Находим SheepSpawner в сцене
		await get_tree().process_frame
		sheep_spawner = get_tree().get_first_node_in_group("sheep_spawner")
		if not sheep_spawner:
				# Пробуем найти по имени узла, если группа не назначена
				sheep_spawner = get_node_or_null("/root/game/SheepSpawner")

		# Находим GameMenu в сцене
		game_menu = get_tree().get_first_node_in_group("game_menu")
		if not game_menu:
				# Пробуем найти по имени узла, если группа не назначена
				game_menu = get_node_or_null("/root/game/GameMenu")

		# Подключаем сигналы нажатия кнопок к функции воспроизведения звука
		spell_sheep_btn.pressed.connect(_on_spell_sheep_pressed)
		sword_up_btn.pressed.connect(_on_sword_up_pressed)
		splash_btn.pressed.connect(_on_button_pressed)
		
		# Подключаем сигналы для подсказок
		spell_sheep_btn.mouse_entered.connect(_on_spell_sheep_mouse_entered)
		spell_sheep_btn.mouse_exited.connect(_on_spell_sheep_mouse_exited)
		sword_up_btn.mouse_entered.connect(_on_sword_up_mouse_entered)
		sword_up_btn.mouse_exited.connect(_on_sword_up_mouse_exited)
		splash_btn.mouse_entered.connect(_on_splash_mouse_entered)
		splash_btn.mouse_exited.connect(_on_splash_mouse_exited)
		
		# Подключаем кнопки MarginContainer2
		$MarginContainer2/VBoxContainer/Start.pressed.connect(_on_start_pressed)
		$MarginContainer2/VBoxContainer/Settings.pressed.connect(_on_settings_pressed)
		$MarginContainer2/VBoxContainer/Exit.pressed.connect(_on_exit_pressed)
		
		# Подключаем кнопку Back в MarginContainer3
		$MarginContainer3/VBoxContainer/Back.pressed.connect(_on_back_pressed)
		
		# Подключаем кнопки выбора языка
		$MarginContainer3/VBoxContainer/HBoxContainer3/Eng.pressed.connect(_on_eng_pressed)
		$MarginContainer3/VBoxContainer/HBoxContainer3/Rus.pressed.connect(_on_rus_pressed)
		
		# Подключаем переключатель FullScreen
		var full_screen_toggle = $MarginContainer3/VBoxContainer/FullScreen
		if full_screen_toggle:
				full_screen_toggle.toggled.connect(_on_full_screen_toggled)
				# Устанавливаем начальное состояние
				var current_mode = DisplayServer.window_get_mode()
				full_screen_toggle.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN || current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		
		# Подключаем кнопки MarginContainer4
		sound1_button.pressed.connect(_on_sound1_pressed)
		music1_button.pressed.connect(_on_music1_pressed)
		settings1_button.pressed.connect(_on_settings1_pressed)
		
		# Изначально скрываем контейнеры настроек
		margin_container2.visible = false
		margin_container3.visible = false
		settings_open = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		pass

func _input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_cancel"):
				_on_settings1_pressed()

func show_spellmenu() -> void:
		# Показываем меню и ставим игру на паузу
		visible = true
		is_visible = true
		is_active = true # Устанавливаем флаг активности

		# Если открыто GameMenu, скрываем его, но паузу не снимаем
		if game_menu and game_menu.has_method("hide_for_spellmenu"):
				game_menu.hide_for_spellmenu()

		get_tree().paused = true

func hide_spellmenu() -> void:
		# Публичный метод для скрытия меню извне (например, из GameMenu)
		visible = false
		is_visible = false
		is_active = false # Сбрасываем флаг активности
		get_tree().paused = false

func _hide_and_resume() -> void:
		# Общая функция для скрытия меню и возобновления игры
		visible = false
		is_visible = false
		is_active = false # Сбрасываем флаг активности

		# Если есть GameMenu, сообщаем ему что SpellMenu закрыто
		if game_menu and game_menu.has_method("on_spellmenu_closed"):
				game_menu.on_spellmenu_closed()

		# Сообщаем Game о выборе заклинания, чтобы запланировать следующее появление
		var game_node = get_tree().get_first_node_in_group("game")
		if game_node and game_node.has_method("schedule_next_spellmenu"):
				game_node.schedule_next_spellmenu()

		# Возобновляем игру через 0.5 секунды
		await get_tree().create_timer(0.5).timeout
		get_tree().paused = false

func _on_spell_sheep_pressed() -> void:
		tap_sound.play()
		# Разблокируем способность овцы
		if sheep_spawner and sheep_spawner.has_method("enable_sheep_spell"):
				sheep_spawner.enable_sheep_spell()
		# Скрываем меню сразу
		_hide_and_resume()

func _on_sword_up_pressed() -> void:
		tap_sound.play()
		# Находим игрока и разблокируем улучшение SwordUP
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("unlock_sword_up"):
				player.unlock_sword_up()
		# Скрываем меню сразу
		_hide_and_resume()

func _on_button_pressed() -> void:
		tap_sound.play()
		# Переключаем атаку игрока на splash
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("enable_splash_attack"):
				player.enable_splash_attack()
		# Скрываем меню сразу
		_hide_and_resume()

# === Обработчики подсказок ===
func _on_spell_sheep_mouse_entered() -> void:
		spell_sheep_tooltip.visible = true

func _on_spell_sheep_mouse_exited() -> void:
		spell_sheep_tooltip.visible = false

func _on_sword_up_mouse_entered() -> void:
		sword_up_tooltip.visible = true

func _on_sword_up_mouse_exited() -> void:
		sword_up_tooltip.visible = false

func _on_splash_mouse_entered() -> void:
		splash_tooltip.visible = true

func _on_splash_mouse_exited() -> void:
		splash_tooltip.visible = false

# === Кнопки MarginContainer2 ===
func _on_start_pressed() -> void:
		# Воспроизводим звук
		tap_sound.play()
		is_active = false
		# Сбрасываем флаг состояния настроек
		settings_open = false
		# Скрываем MarginContainer2 и MarginContainer3
		margin_container2.visible = false
		margin_container3.visible = false


func _on_settings_pressed() -> void:
		# Воспроизводим звук
		tap_sound.play()
		# Запоминаем, что настройки были открыты
		settings_open = true
		# Скрываем главное меню (MarginContainer2) и показываем настройки (MarginContainer3)
		margin_container2.visible = false
		margin_container3.visible = true


func _on_exit_pressed() -> void:
		# Воспроизводим звук
		tap_sound.play()
		# Ждем 1.0 секунды и закрываем игру
		await get_tree().create_timer(1.0).timeout
		get_tree().quit()


# === Кнопки MarginContainer3 (настройки) ===
func _on_back_pressed() -> void:
		# Воспроизводим звук
		tap_sound.play()
		# Сбрасываем флаг, так как мы вышли из настроек обратно в главное меню
		settings_open = false
		# Скрываем настройки (MarginContainer3) и показываем главное меню (MarginContainer2)
		margin_container3.visible = false
		margin_container2.visible = true


func _on_eng_pressed() -> void:
		# Воспроизводим звук
		tap_sound.play()
		# Устанавливаем английский язык
		Localization.set_locale("en")
		# Обновляем все тексты
		_update_all_localized_texts()


func _on_rus_pressed() -> void:
		# Воспроизводим звук
		tap_sound.play()
		# Устанавливаем русский язык
		Localization.set_locale("ru")
		# Обновляем все тексты
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
		# Воспроизводим звук
		tap_sound.play()
		if is_fullscreen:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# === Кнопки MarginContainer4 ===
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
		if settings_open:
				# Если настройки открыты, скрываем MarginContainer2 и MarginContainer3
				margin_container2.visible = false
				margin_container3.visible = false
				settings_open = false
		else:
				# Если настройки закрыты, показываем MarginContainer2
				margin_container2.visible = true
				margin_container3.visible = false
				settings_open = true
