extends Node2D

@export_category("Настройки спавна")
@export var player_node: NodePath  # Путь к игроку
@export var spawn_radius: float = 400.0  # Радиус спавна вокруг игрока
@export var min_spawn_distance: float = 100.0  # Минимальная дистанция от игрока

@export_category("Волны врагов")
@export var waves: Array[WaveConfig] = []  # Массив волн для настройки в инспекторе

var _player: Node2D = null
var _game_timer: float = 0.0  # Общее время игры
var _spawned_waves: Array[int] = []  # Индексы уже заспавненных волн
var _active_wave_timers: Array[float] = []  # Таймеры для активных волн

func _ready() -> void:
	# Ждем пока игрок будет готов
	await get_tree().process_frame
	
	if has_node(player_node):
		_player = get_node(player_node)
	else:
		_player = get_tree().get_first_node_in_group("player")
	
	if _player == null:
		print("[EnemySpawner] Предупреждение: Игрок не найден!")
	
	# Инициализируем таймеры для волн
	_active_wave_timers.resize(waves.size())
	for i in range(_active_wave_timers.size()):
		_active_wave_timers[i] = 0.0

func _process(delta: float) -> void:
	if _player == null or waves.is_empty():
		return
	
	# Обновляем общее время игры
	_game_timer += delta
	
	# Проверяем каждую волну
	for i in range(waves.size()):
		var wave = waves[i]
		
		# Если волна еще не была заспавнена и пришло её время
		if i not in _spawned_waves and _game_timer >= wave.spawn_time:
			_spawn_wave(i)
		
		# Если волна активна (еще не все враги заспавнены)
		if i in _spawned_waves and i < _active_wave_timers.size():
			# Продолжаем спавнить врагов из этой волны если нужно
			if wave.spawn_count > 1:
				_active_wave_timers[i] += delta
				if _active_wave_timers[i] >= wave.spawn_interval:
					# Проверяем, сколько врагов уже заспавнено
					var spawned_count = _count_enemies_by_scene(wave.enemy_scene)
					if spawned_count < wave.spawn_count:
						_spawn_enemy(wave.enemy_scene)
					_active_wave_timers[i] = 0.0

func _spawn_wave(wave_index: int) -> void:
	var wave = waves[wave_index]
	
	if wave.enemy_scene == null:
		print("[EnemySpawner] Ошибка: В волне ", wave_index, " не назначена сцена врага!")
		return
	
	print("[EnemySpawner] Волна ", wave_index, " началась! Время: ", _game_timer, " сек")
	
	# Спавним первого врага сразу
	_spawn_enemy(wave.enemy_scene)
	
	# Если в волне больше одного врага, начинаем таймер для остальных
	if wave.spawn_count > 1:
		_active_wave_timers[wave_index] = 0.0
	
	_spawned_waves.append(wave_index)

func _spawn_enemy(enemy_scene: PackedScene) -> void:
	if enemy_scene == null or _player == null:
		return
	
	var enemy = enemy_scene.instantiate()
	
	# Спавним врага в случайной позиции вокруг игрока
	var spawn_position = _get_random_spawn_position()
	enemy.global_position = spawn_position
	
	get_parent().add_child(enemy)
	print("[EnemySpawner] Заспавнен враг на позиции: ", spawn_position)

func _get_random_spawn_position() -> Vector2:
	# Генерируем случайный угол
	var angle = randf() * TAU
	
	# Генерируем случайное расстояние в пределах радиуса
	var distance = randf_range(min_spawn_distance, spawn_radius)
	
	# Вычисляем позицию относительно игрока
	return _player.global_position + Vector2(cos(angle), sin(angle)) * distance

func _count_enemies_by_scene(scene: PackedScene) -> int:
	var count = 0
	for child in get_parent().get_children():
		# Проверяем, является ли ребенок экземпляром этой сцены
		if is_instance_valid(child) and child.scene_file_path == scene.resource_path:
			count += 1
	return count

# Метод для добавления волны программно (если нужно)
func add_wave(spawn_time_seconds: float, enemy_scene: PackedScene, count: int = 1, interval: float = 1.0) -> void:
	var wave = WaveConfig.new()
	wave.spawn_time = spawn_time_seconds
	wave.enemy_scene = enemy_scene
	wave.spawn_count = count
	wave.spawn_interval = interval
	waves.append(wave)
	print("[EnemySpawner] Добавлена новая волна: время=", spawn_time_seconds, " сек, врагов=", count)
