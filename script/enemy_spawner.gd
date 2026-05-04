extends Node2D

@export var waves: Array[SpawnWave]  # Массив волн врагов
@export var grass_layer: TileMapLayer
@export var min_distance_from_camera: float = 100.0

var _game_timer: float = 0.0
var _valid_spawn_positions: Array[Vector2] = []

func _ready() -> void:
	if grass_layer == null:
		print("Ошибка: не назначен слой Grass в инспекторе!")
		return
	
	_find_valid_spawn_positions()
	
	# Инициализируем все волны
	for wave in waves:
		wave.reset()

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

func _process(delta: float) -> void:
	_game_timer += delta
	
	# Обрабатываем каждую волну
	for wave in waves:
		# Проверяем, настало ли время для этой волны
		if _game_timer >= wave.start_time and not wave.is_wave_finished():
			_update_wave(wave, delta)

func _update_wave(wave: SpawnWave, delta: float) -> void:
	# Проверяем количество текущих врагов этой волны на сцене
	var current_enemies = get_tree().get_nodes_in_group("enemy")
	# Здесь можно добавить фильтрацию по типу врага, если нужно
	
	if current_enemies.size() >= wave.max_enemies:
		return
	
	# Обновляем таймер спавна
	wave._spawn_timer += delta
	if wave._spawn_timer >= wave.spawn_interval:
		wave._spawn_timer = 0.0
		_spawn_enemy(wave)

func _spawn_enemy(wave: SpawnWave) -> void:
	if wave.enemy_scene == null:
		print("Ошибка: в волне не назначена сцена врага!")
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
	
	var enemy = wave.enemy_scene.instantiate()
	enemy.global_position = spawn_position
	get_parent().add_child(enemy)
	
	wave._spawned_count += 1
