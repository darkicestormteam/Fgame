extends CanvasLayer


var is_visible: bool = false
var is_active: bool = false # Флаг активности меню (открыто и ждет выбора)

@onready var tap_sound: AudioStreamPlayer = $Tap
@onready var spell_sheep_btn: TextureButton = $MarginContainer/HBoxContainer/SpellSheep
@onready var sword_up_btn: TextureButton = $MarginContainer/HBoxContainer/SwordUP
@onready var splash_btn: TextureButton = $MarginContainer/HBoxContainer/Splash

# Ссылка на SheepSpawner
var sheep_spawner: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Скрываем меню при старте
	visible = false
	is_active = false
	
	# Находим SheepSpawner в сцене
	await get_tree().process_frame
	sheep_spawner = get_tree().get_first_node_in_group("sheep_spawner")
	if not sheep_spawner:
		# Пробуем найти по имени узла, если группа не назначена
		sheep_spawner = get_node_or_null("/root/game/SheepSpawner")
	
	# Подключаем сигналы нажатия кнопок к функции воспроизведения звука
	spell_sheep_btn.pressed.connect(_on_spell_sheep_pressed)
	sword_up_btn.pressed.connect(_on_sword_up_pressed)
	splash_btn.pressed.connect(_on_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_spellmenu() -> void:
	# Показываем меню и ставим игру на паузу
	visible = true
	is_visible = true
	is_active = true # Устанавливаем флаг активности
	get_tree().paused = true

func _hide_and_resume() -> void:
	# Общая функция для скрытия меню и возобновления игры
	visible = false
	is_visible = false
	is_active = false # Сбрасываем флаг активности
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
