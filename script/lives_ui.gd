extends Control

@onready var hearts_container: HBoxContainer = $HeartsContainer

var heart_texture: Texture2D
var current_lives: int = 3

func _ready() -> void:
	# Загружаем текстуру сердца
	heart_texture = load("res://assets/heart.png")
	
	# Получаем ссылку на игрока и слушаем изменения жизней
	var player = get_tree().get_first_node_in_group("player")
	if player:
		current_lives = player.current_lives
		update_hearts()
		
		# Можно подключить сигнал если он есть, или обновлять в _process
		set_process(true)

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.current_lives != current_lives:
		current_lives = player.current_lives
		update_hearts()

func update_hearts() -> void:
	# Очищаем контейнер
	for child in hearts_container.get_children():
		child.queue_free()
	
	# Создаем нужное количество сердец
	for i in range(current_lives):
		var texture_rect = TextureRect.new()
		texture_rect.texture = heart_texture
		texture_rect.custom_minimum_size = Vector2(40, 40)
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hearts_container.add_child(texture_rect)
