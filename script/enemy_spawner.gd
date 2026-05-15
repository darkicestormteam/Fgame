extends Node2D

# Глобальные настройки (одинаковые для всех волн или специфичные для карты)
@export var grass_layer: TileMapLayer
@export var min_distance_from_camera: float = 100.0

# Конфигурация волн
@export var wave_configs: Array[WaveConfig] = []

var _spawn_timer: Timer
var _lifetime_timer: Timer
var _activation_timers: Array[Timer] = []
var _valid_spawn_positions: Array[Vector2] = []
var _is_active: bool = false
var _current_wave_config: WaveConfig = null
var _game_time: float = 0.0

# Ссылка на сцену preview
var _preview_node: ColorRect = null

func _ready() -> void:
	if grass_layer == null:
		push_error("Ошибка: не назначен слой Grass в инспекторе!")
		return
	
	_find_valid_spawn_positions()
	
	# Настраиваем базовый таймер спавна (интервал будет обновляться при старте волны)
	_spawn_timer = Timer.new()
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	
	# Если волн нет, ничего не делаем
	if wave_configs.is_empty():
		print("[EnemySpawner] Список волн пуст. Добавьте элементы в wave_configs.")
		# Для тестов можно активировать сразу, если нужно, но лучше оставить пустым
		return
	
	# Ищем сцену preview в дереве
	_preview_node = get_tree().get_first_node_in_group("preview")
	
	# Создаем таймеры активации для каждой волны
	for i in range(wave_configs.size()):
		var config = wave_configs[i]
		var activation_timer = Timer.new()
		activation_timer.wait_time = config.activation_time
		activation_timer.one_shot = true
		# Передаем индекс волны, чтобы найти конфиг при срабатывании
		activation_timer.timeout.connect(_on_activation_timer_timeout.bind(i))
		add_child(activation_timer)
		_activation_timers.append(activation_timer)
		activation_timer.start()
		print("[EnemySpawner] Волна %d запланирована на %.2f сек" % [i, config.activation_time])

func _on_activation_timer_timeout(wave_index: int) -> void:
	if wave_index >= wave_configs.size():
		return
		
	var config = wave_configs[wave_index]
	print("[EnemySpawner] Активация волны %d (Время: %.2f, Длительность: %.2f)" % [wave_index, config.activation_time, config.lifetime])
	
	# Если это первая волна (номер 0), запускаем preview с анимацией Gnom и ставим паузу
	if wave_index == 0:
		await _play_preview_and_pause("Gnom")
	# Если это вторая волна (номер 1), запускаем preview с анимацией Snake и ставим паузу
	elif wave_index == 1:
		await _play_preview_and_pause("Snake")
	# Если это третья волна (номер 2), запускаем preview с анимацией Gnom_Snake и ставим паузу
	elif wave_index == 2:
		await _play_preview_and_pause("Gnom_Snake")
		# Включаем музыку босса на третьей волне
		_play_boss_music()
	# Если это четвертая волна (номер 3), запускаем preview с анимацией Bear и ставим паузу
	elif wave_index == 3:
		await _play_preview_and_pause("Bear")
		# Возвращаем музыку world на четвертой волне
		_play_world_music()
	
	_current_wave_config = config
	activate_spawner(config.lifetime)

func _play_preview_and_pause(animation_name: String = "Gnom") -> void:
	if _preview_node and _preview_node.has_method("play_preview"):
		# Ставим паузу в игре
		get_tree().paused = true
		
		# Запускаем анимацию preview с указанным именем
		await _preview_node.play_preview(animation_name)
		
		# Снимаем паузу после завершения анимации
		get_tree().paused = false

func activate_spawner(lifetime: float = 0.0) -> void:
	if _current_wave_config == null:
		push_error("Активация вызвана без текущей конфигурации волны!")
		return

	_is_active = true
	
	# Устанавливаем интервал спавна из текущей волны
	_spawn_timer.wait_time = _current_wave_config.spawn_interval
	_spawn_timer.start()
	
	# Обработка времени жизни
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
		print("[EnemySpawner] Волна активна %.2f сек" % lifetime)
	else:
		print("[EnemySpawner] Волна активна бессрочно")

func deactivate_spawner() -> void:
	_is_active = false
	_spawn_timer.stop()
	_current_wave_config = null
	print("[EnemySpawner] Волна завершена")

func _on_lifetime_expired() -> void:
	deactivate_spawner()
	# Опционально: можно автоматически запускать следующую волну, если логика требует
	# Но сейчас каждая волна имеет свой таймер активации, так что просто ждем следующего таймера

func _find_valid_spawn_positions() -> void:
	_valid_spawn_positions.clear()
	if grass_layer == null: return
	
	var used_cells = grass_layer.get_used_cells()
	for cell in used_cells:
		var world_pos = grass_layer.map_to_local(cell)
		_valid_spawn_positions.append(world_pos)
	
	if _valid_spawn_positions.is_empty():
		push_warning("Предупреждение: слой Grass не содержит тайлов!")

func _is_position_outside_camera(position: Vector2) -> bool:
	var viewport = get_viewport()
	if viewport == null: return true
	
	var camera = viewport.get_camera_2d()
	if camera == null: return true
	
	var screen_size = viewport.get_visible_rect().size
	var camera_pos = camera.global_position
	
	var half_screen = screen_size / 2.0
	var left_edge = camera_pos.x - half_screen.x - min_distance_from_camera
	var right_edge = camera_pos.x + half_screen.x + min_distance_from_camera
	var top_edge = camera_pos.y - half_screen.y - min_distance_from_camera
	var bottom_edge = camera_pos.y + half_screen.y + min_distance_from_camera
	
	if position.x < left_edge or position.x > right_edge: return true
	if position.y < top_edge or position.y > bottom_edge: return true
	
	return false

func _on_spawn_timer_timeout() -> void:
	if not _is_active or _current_wave_config == null:
		return
	
	var current_enemies = get_tree().get_nodes_in_group("enemy")
	
	if current_enemies.size() >= _current_wave_config.max_enemies:
		return
	
	var enemy_scene = _select_enemy_scene(_current_wave_config)
	if enemy_scene == null:
		# Если сцены не настроены в волне, пропускаем спавн, но не останавливаем таймер навсегда (вдруг подгрузится)
		return
	
	if _valid_spawn_positions.is_empty():
		return
	
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
	
	if not found_valid_position:
		var random_index = randi() % _valid_spawn_positions.size()
		spawn_position = grass_layer.to_global(_valid_spawn_positions[random_index])
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	get_parent().add_child(enemy)

func _select_enemy_scene(config: WaveConfig) -> PackedScene:
	if config.enemy_scenes.is_empty():
		return null
	
	if config.spawn_weights.is_empty() or config.spawn_weights.size() != config.enemy_scenes.size():
		var random_index = randi() % config.enemy_scenes.size()
		return config.enemy_scenes[random_index]
	
	var total_weight = 0
	for weight in config.spawn_weights:
		total_weight += weight
	
	var random_value = randi() % total_weight
	var cumulative_weight = 0
	
	for i in range(config.enemy_scenes.size()):
		cumulative_weight += config.spawn_weights[i]
		if random_value < cumulative_weight:
			return config.enemy_scenes[i]
	
	return config.enemy_scenes[config.enemy_scenes.size() - 1]

func _play_boss_music() -> void:
	# Находим узел World (обычная музыка) и Bossmusic в сцене
	var world_music = get_node_or_null("/root/game/Player/World")
	var boss_music = get_node_or_null("/root/game/Player/Bossmusic")
	
	if world_music and world_music is AudioStreamPlayer:
		world_music.stop()
	
	if boss_music and boss_music is AudioStreamPlayer:
		boss_music.play()

func _play_world_music() -> void:
	# Находим узел World (обычная музыка) и Bossmusic в сцене
	var world_music = get_node_or_null("/root/game/Player/World")
	var boss_music = get_node_or_null("/root/game/Player/Bossmusic")
	
	if boss_music and boss_music is AudioStreamPlayer:
		boss_music.stop()
	
	if world_music and world_music is AudioStreamPlayer:
		world_music.play()
