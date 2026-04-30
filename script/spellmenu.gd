extends CanvasLayer


var is_visible: bool = false

@onready var tap_sound: AudioStreamPlayer = $Tap
@onready var spell_sheep_btn: TextureButton = $MarginContainer/HBoxContainer/SpellSheep
@onready var sword_up_btn: TextureButton = $MarginContainer/HBoxContainer/SwordUP
@onready var test_btn: TextureButton = $MarginContainer/HBoxContainer/Test

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Скрываем меню при старте
	visible = false
	
	# Подключаем сигналы нажатия кнопок
	spell_sheep_btn.pressed.connect(_on_button_pressed)
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

func _on_button_pressed() -> void:
	# Воспроизводим звук нажатия
	tap_sound.play()
	
	# Продолжаем игру через 0.5 секунд
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = false
	visible = false
	is_visible = false
