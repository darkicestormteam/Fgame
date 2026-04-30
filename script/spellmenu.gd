extends CanvasLayer


var is_visible: bool = false

@onready var tap_sound: AudioStreamPlayer = $Tap
@onready var spell_sheep_btn: TextureButton = $MarginContainer/HBoxContainer/SpellSheep
@onready var sword_up_btn: TextureButton = $MarginContainer/HBoxContainer/SwordUP
@onready var test_btn: TextureButton = $MarginContainer/HBoxContainer/Test

# Ссылка на SheepSpawner
var sheep_spawner: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Скрываем меню при старте
	visible = false
	
	# Находим SheepSpawner в сцене
	await get_tree().process_frame
	sheep_spawner = get_tree().get_first_node_in_group("sheep_spawner")
	if not sheep_spawner:
		# Пробуем найти по имени узла, если группа не назначена
		sheep_spawner = get_node_or_null("/root/game/SheepSpawner")
	
	# Подключаем сигналы нажатия кнопок к функции воспроизведения звука
	spell_sheep_btn.pressed.connect(_on_spell_sheep_pressed)
	sword_up_btn.pressed.connect(_on_button_pressed)
	test_btn.pressed.connect(_on_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_spellmenu() -> void:
	# Показываем меню и ставим игру на паузу
	visible = true
	is_visible = true
	get_tree().paused = true

func _on_spell_sheep_pressed() -> void:
	tap_sound.play()
	# Разблокируем способность овцы
	if sheep_spawner and sheep_spawner.has_method("enable_sheep_spell"):
		sheep_spawner.enable_sheep_spell()
	# Скрываем меню сразу
	visible = false
	is_visible = false
	# Возобновляем игру через 0.5 секунды
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = false

func _on_button_pressed() -> void:
	tap_sound.play()
	# Проверяем, какая кнопка была нажата
	if get_focus_owner() == sword_up_btn:
		# Разблокируем улучшение SwordUP для игрока
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("unlock_sword_up"):
			player.unlock_sword_up()
	# Скрываем меню сразу
	visible = false
	is_visible = false
	# Возобновляем игру через 0.5 секунды
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = false
