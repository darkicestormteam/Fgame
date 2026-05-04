extends Node2D

# Структура для хранения настроек одной волны
class WaveConfig:
	var activation_time: float = 0.0
	var lifetime: float = 0.0

# Массив сцен врагов для спавна
@export var enemy_scenes: Array[PackedScene] = []
# Веса вероятности для каждого врага (должны соответствовать количеству сцен)
@export var spawn_weights: Array[int] = []
@export var max_enemies: int = 30
@export var spawn_interval: float = 0.5
@export var grass_layer: TileMapLayer
@export var min_distance_from_camera: float = 100.0  # Минимальное расстояние от края камеры

# Настройки волн
@export var waves: Array[WaveConfig] = []

var _spawn_timer: Timer
var _lifetime_timer: Timer
var _activation_timers: Array[Timer] = []
var _valid_spawn_positions: Array[Vector2] = []
var _is_active: bool = false  # Изначально не активен, активируется по таймеру
var _game_time: float = 0.0

func _ready() -> void:
	if grass_layer == null:
		print("Ошибка: не назначен слой Grass в инспекторе!")
		return
	
	_find_valid_spawn_positions()
	
	# Настраиваем таймер спавна (но не запускаем его сразу)
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	
	# Создаем таймеры активации для каждой волны
	for wave_config in waves:
		var activation_timer = Timer.new()
		activation_timer.wait_time = wave_config.activation_time
		activation_timer.one_shot = true
		activation_timer.timeout.connect(_on_activation_timer_timeout.bind(wave_config))
		add_child(activation_timer)
		_activation_timers.append(activation_timer)
		activation_timer.start()
		print("[EnemySpawner] Запланирована активация на ", wave_config.activation_time, " секунде")
	
	# Если нет волн, ничего не делаем (спавнер не активируется автоматически)
	if waves.is_empty():
		print("[EnemySpawner] Нет настроенных волн")

# Метод вызывается при наступлении времени активации волны
func _on_activation_timer_timeout(wave_config: WaveConfig) -> void:
	print("[EnemySpawner] Активация спавнера на ", wave_config.activation_time, " секунде игры")
	print("[EnemySpawner] Время жизни волны: ", wave_config.lifetime, " сек")
	activate_spawner(wave_config.lifetime)

# Метод для ручной активации спавнера (если нужно включать/выключать программно)
func activate_spawner(lifetime: float = 0.0) -> void:
	_is_active = true
	_spawn_timer.start()
	
	# Если указано время жизни, запускаем таймер
	if lifetime > 0:
		if _lifetime_timer:
			_lifetime_timer.stop()
			_lifetime_timer.wait_time = lifetime
			_lifetime_timer.start()
		else:
			_lifetime_timer = Timer.new()
			_lifetime_timer.wait_time = lifetime
			_lifetime_timer.one_shot = true
			_lifetime_timer.timeout.connect(_on_lifetime_expired)
			add_child(_lifetime_timer)
			_lifetime_timer.start()
		print("[EnemySpawner] Активирован на ", lifetime, " секунд")
	else:
		print("[EnemySpawner] Активирован бессрочно")

# Метод для остановки спавна
func deactivate_spawner() -> void:
	_is_active = false
	_spawn_timer.stop()
	print("[EnemySpawner] Деактивирован")

func _on_lifetime_expired() -> void:
	deactivate_spawner()
	print("[EnemySpawner] Время жизни истекло, спавн остановлен")

func _find_valid_spawn_positions() -> void:
	_valid_spawn_positions.clear()
	var used_cells = grass_layer.get_used_cells()
	for cell in used_cells:
		var world_pos = grass_layer.map_to_local(cell)
		_valid_spawn_positions.append(world_pos)
	
	if _valid_spawn_positions.is_empty():
		print("Предупреждение: слой Grass не содержит тайлов!")

func _is_position_outside_camera(position: Vector2) -> bool:
	var viewport = get_viewport()
	if viewport == null:
		return true
	
	var camera = viewport.get_camera_2d()
	if camera == null:
		return true
	
	var screen_size = viewport.get_visible_rect().size
	var camera_pos = camera.global_position
	
	# Вычисляем границы видимой области камеры
	var half_screen = screen_size / 2.0
	var left_edge = camera_pos.x - half_screen.x - min_distance_from_camera
	var right_edge = camera_pos.x + half_screen.x + min_distance_from_camera
	var top_edge = camera_pos.y - half_screen.y - min_distance_from_camera
	var bottom_edge = camera_pos.y + half_screen.y + min_distance_from_camera
	
	# Проверяем, находится ли позиция за пределами камеры
	if position.x < left_edge or position.x > right_edge:
		return true
	if position.y < top_edge or position.y > bottom_edge:
		return true
	
	return false

func _on_spawn_timer_timeout() -> void:
	if not _is_active:
		return
	
	var current_enemies = get_tree().get_nodes_in_group("enemy")
	
	if current_enemies.size() >= max_enemies:
		return
	
	# Выбираем сцену врага на основе весов
	var enemy_scene = _select_enemy_scene()
	if enemy_scene == null:
		print("Ошибка: не назначены сцены врагов в enemy_scenes!")
		return
	
	if _valid_spawn_positions.is_empty():
		print("Ошибка: нет доступных позиций для спавна на слое Grass!")
		return
	
	# Пытаемся найти позицию за пределами камеры
	var max_attempts = 10
	var spawn_position: Vector2
	var found_valid_position = false
	
	for attempt in range(max_attempts):
		var random_index = randi() % _valid_spawn_positions.size()
		var candidate_position = _valid_spawn_positions[random_index]
		var global_candidate_position = grass_layer.to_global(candidate_position)
		
		if _is_position_outside_camera(global_candidate_position):
			spawn_position = global_candidate_position
			found_valid_position = true
			break
	
	# Если не нашли позицию за пределами камеры, используем случайную
	if not found_valid_position:
		var random_index = randi() % _valid_spawn_positions.size()
		spawn_position = grass_layer.to_global(_valid_spawn_positions[random_index])
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	get_parent().add_child(enemy)

# Метод для выбора сцены врага на основе весов вероятности
func _select_enemy_scene() -> PackedScene:
	if enemy_scenes.is_empty():
		return null
	
	# Если веса не заданы или их количество не совпадает, используем равномерное распределение
	if spawn_weights.is_empty() or spawn_weights.size() != enemy_scenes.size():
		var random_index = randi() % enemy_scenes.size()
		return enemy_scenes[random_index]
	
	# Вычисляем общую сумму весов
	var total_weight = 0
	for weight in spawn_weights:
		total_weight += weight
	
	# Выбираем случайное число от 0 до общей суммы весов
	var random_value = randi() % total_weight
	var cumulative_weight = 0
	
	for i in range(enemy_scenes.size()):
		cumulative_weight += spawn_weights[i]
		if random_value < cumulative_weight:
			return enemy_scenes[i]
	
	# На всякий случай возвращаем последний элемент
	return enemy_scenes[enemy_scenes.size() - 1]
