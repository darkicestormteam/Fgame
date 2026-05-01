extends Node

# Сигналы, чтобы другие объекты узнавали об изменениях
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_over_triggered

# Переменные состояния игры
var score: int = 0
var current_lives: int = 3
var max_lives: int = 3
var is_game_over: bool = false

func _ready():
	# Менеджер создается при старте игры
	pass

# Функция для добавления очков
func add_score(amount: int):
	if is_game_over:
		return
	score += amount
	score_changed.emit(score)  # Сообщаем всем, что счет изменился
	print("Score: ", score)

# Функция для изменения жизней (положительно или отрицательно)
func add_life(amount: int):
	if is_game_over:
		return
	current_lives += amount
	current_lives = clamp(current_lives, 0, max_lives)
	lives_changed.emit(current_lives)  # Сообщаем всем, что жизни изменились
	print("Lives: ", current_lives)

# Функция для установки максимального количества жизней
func set_max_lives(amount: int):
	max_lives = amount
	current_lives = min(current_lives, max_lives)
	lives_changed.emit(current_lives)

# Функция для запуска конца игры
func trigger_game_over():
	if is_game_over:
		return
	is_game_over = true
	game_over_triggered.emit()  # Сообщаем всем, что игра окончена
	print("Game Over!")

# Функция для перезапуска (опционально)
func restart_game():
	score = 0
	current_lives = max_lives
	is_game_over = false
	# Здесь можно добавить перезапуск сцены, если нужно
	# get_tree().reload_current_scene()
