extends Node2D

@export var enemy_scene: PackedScene
@export var max_enemies: int = 30
@export var spawn_interval: float = 0.5

var _tile_map_layer: TileMapLayer = null
var _grass_terrain_set: int = 0
var _grass_terrain: int = 0  # terrain_0 = Grass

func _ready() -> void:
	print("[EnemySpawner] Инициализация спавнера врагов...")
	
	# Находим слой Grass в TileMap
	var tile_map = get_node_or_null("/root/game/TileMap")
	if tile_map == null:
		print("[EnemySpawner] ОШИБКА: Не найден узел TileMap в сцене game!")
		tile_map = get_tree().get_first_node_in_group("tilemap")
		if tile_map == null:
			print("[EnemySpawner] ОШИБКА: Не найден TileMap через группу 'tilemap'!")
	
	if tile_map:
		print("[EnemySpawner] TileMap найден: ", tile_map.name)
		_tile_map_layer = tile_map.get_node_or_null("Grass")
		if _tile_map_layer == null:
			print("[EnemySpawner] ОШИБКА: Слой 'Grass' не найден в TileMap!")
			print("[EnemySpawner] Доступные дочерние узлы TileMap:")
			for child in tile_map.get_children():
				print("  - ", child.name, " (тип: ", child.get_class(), ")")
		else:
			print("[EnemySpawner] Слой Grass найден: ", _tile_map_layer.name)
			# Проверяем TileSet
			if _tile_map_layer.tile_set == null:
				print("[EnemySpawner] ОШИБКА: TileSet в слое Grass не назначен!")
			else:
				print("[EnemySpawner] TileSet найден. Проверяем terrain...")
				# В Godot 4.x нет метода get_terrain_set_count(), проверяем напрямую
				# Предполагаем, что terrain set 0 существует и terrain 0 - это Grass
				_grass_terrain_set = 0
				_grass_terrain = 0
				var test_terrain_name = _tile_map_layer.tile_set.get_terrain_name(_grass_terrain_set, _grass_terrain)
				print("[EnemySpawner] Проверяем terrain set=", _grass_terrain_set, " terrain=", _grass_terrain)
				print("[EnemySpawner] Название terrain: '", test_terrain_name, "'")
				if test_terrain_name == "" or test_terrain_name == null:
					print("[EnemySpawner] ПРЕДУПРЕЖДЕНИЕ: Terrain с индексом 0 не найден или пуст. Возможно, нужно настроить индексы terrain в TileSet.")
	
	if _tile_map_layer == null:
		push_warning("[EnemySpawner] Критическая ошибка: Слой Grass не найден! Враги будут появляться в случайных местах.")
	
	# Проверяем enemy_scene
	if enemy_scene == null:
		print("[EnemySpawner] ОШИБКА: enemy_scene не назначена в инспекторе!")
	else:
		print("[EnemySpawner] Enemy scene назначена: ", enemy_scene.resource_path)
	
	# Настраиваем таймер
	var timer = $TimerSpawner
	if timer:
		timer.wait_time = spawn_interval
		timer.autostart = true
		timer.timeout.connect(_on_timer_timeout)
		print("[EnemySpawner] Таймер настроен: интервал = ", spawn_interval, " сек, макс врагов = ", max_enemies)
	else:
		print("[EnemySpawner] ОШИБКА: TimerSpawner не найден среди дочерних узлов!")

func _on_timer_timeout() -> void:
	# Проверяем текущее количество врагов
	var current_enemies = get_tree().get_nodes_in_group("enemy").size()
	
	print("[EnemySpawner] Таймер сработал. Текущее количество врагов: ", current_enemies, " / ", max_enemies)
	
	if current_enemies >= max_enemies:
		print("[EnemySpawner] Достигнут лимит врагов (", max_enemies, "). Пропуск спавна.")
		return
	
	# Пытаемся найти подходящее место для спавна
	var spawn_position = _get_random_grass_position()
	
	if spawn_position != Vector2.ZERO:
		print("[EnemySpawner] Найдена позиция для спавна: ", spawn_position)
		_spawn_enemy(spawn_position)
	else:
		print("[EnemySpawner] Не удалось найти подходящую позицию для спавна на Grass!")

func _get_random_grass_position() -> Vector2:
	if _tile_map_layer == null:
		print("[EnemySpawner] _get_random_grass_position: ОШИБКА - Слой Grass не найден! Возвращаем ZERO.")
		return Vector2.ZERO
	
	var tile_set = _tile_map_layer.tile_set
	if tile_set == null:
		print("[EnemySpawner] _get_random_grass_position: ОШИБКА - TileSet не назначен!")
		return Vector2.ZERO
	
	# Получаем все используемые клетки на слое Grass
	var used_rect = _tile_map_layer.get_used_rect()
	print("[EnemySpawner] _get_random_grass_position: get_used_rect() = ", used_rect)
	
	if used_rect.size == Vector2i.ZERO:
		print("[EnemySpawner] _get_random_grass_position: ОШИБКА - get_used_rect() вернул пустой прямоугольник!")
		return Vector2.ZERO
	
	# Пробуем найти случайную клетку с травой (несколько попыток)
	var max_attempts = 50
	for i in range(max_attempts):
		var random_x = randi_range(used_rect.position.x, used_rect.end.x - 1)
		var random_y = randi_range(used_rect.position.y, used_rect.end.y - 1)
		var cell_coords = Vector2i(random_x, random_y)
		
		# Проверяем, существует ли клетка
		var cell_tile_data = _tile_map_layer.get_cell_tile_data(cell_coords)
		
		if cell_tile_data == null:
			if i < 5:
				print("[EnemySpawner] Попытка ", i, ": Клетка ", cell_coords, " пуста (нет tile_data)")
			continue
		
		# Проверяем источник данных (для отладки)
		if i < 3:
			print("[EnemySpawner] Попытка ", i, ": Клетка ", cell_coords, " имеет tile_data")
			print("  - Количество источников: ", cell_tile_data.get_source_count())
			
			# Проверяем все источники в клетке
			for src_id in range(cell_tile_data.get_source_count()):
				var source_id = cell_tile_data.get_source_id(src_id)
				if i < 3:
					print("    - Источник ", src_id, ": ID=", source_id)
				
				# Проверяем terrain для этого источника
				# В Godot 4.x terrain привязан к источнику (source)
				# Метод get_terrain_set_count() отсутствует в TileSet, поэтому сразу проверяем terrain type
				# Если terrain set не существует, get_terrain_type вернет -1 или вызовет ошибку
				var terrain_type = -1
				# Используем try-catch подход через проверку существования метода или просто вызываем
				# В GDScript нет try-catch, но можно проверить через has_method или просто вызвать
				# Для простоты вызываем напрямую и ловим ошибку через print, если она возникнет
				# Но лучше просто вызвать и предположить, что set существует
				terrain_type = cell_tile_data.get_terrain_type(_grass_terrain_set)
				if i < 3:
					print("      - Terrain type (set=", _grass_terrain_set, "): ", terrain_type, " (ожидаем ", _grass_terrain, ")")
				
				if terrain_type == _grass_terrain:
					# Преобразуем координаты клетки в мировые координаты
					var local_pos = _tile_map_layer.map_to_local(cell_coords)
					var world_position = _tile_map_layer.to_global(local_pos + Vector2(0.5, 0.5) * _tile_map_layer.tile_set.tile_size)
					print("[EnemySpawner] НАЙДЕНА трава! Клетка=", cell_coords, " Мир.позиция=", world_position)
					return world_position
	
	print("[EnemySpawner] После ", max_attempts, " попыток не найдено подходящей клетки с Grass!")
	print("[EnemySpawner] Подсказка: Проверьте, что в TileSet настроены terrain'ы и клетки имеют правильный terrain type.")
	return Vector2.ZERO

func _spawn_enemy(position: Vector2) -> void:
	if enemy_scene == null:
		print("[EnemySpawner] _spawn_enemy: ОШИБКА - Enemy scene не назначена в инспекторе!")
		push_error("Enemy scene не назначена в инспекторе!")
		return
	
	print("[EnemySpawner] Спавн врага на позиции: ", position)
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	get_parent().add_child(enemy)
	print("[EnemySpawner] Враг успешно создан и добавлен в сцену!")
