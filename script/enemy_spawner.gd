extends Node2D

@export var enemy_scene: PackedScene
@export var max_enemies: int = 30
@export var spawn_interval: float = 0.5

var _tile_map_layer: TileMapLayer = null
var _grass_terrain_set: int = 0
var _grass_terrain: int = 0  # terrain_0 = Grass

func _ready() -> void:
	# Находим слой Grass в TileMap
	var tile_map = get_node_or_null("../TileMap")
	if tile_map:
		_tile_map_layer = tile_map.get_node_or_null("Grass")
	
	if _tile_map_layer == null:
		push_warning("Слой Grass не найден! Враги могут появляться в случайных местах.")
	
	# Настраиваем таймер
	var timer = $TimerSpawner
	if timer:
		timer.wait_time = spawn_interval
		timer.autostart = true
		timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	# Проверяем текущее количество врагов
	var current_enemies = get_tree().get_nodes_in_group("enemy").size()
	
	if current_enemies >= max_enemies:
		return
	
	# Пытаемся найти подходящее место для спавна
	var spawn_position = _get_random_grass_position()
	
	if spawn_position != Vector2.ZERO:
		_spawn_enemy(spawn_position)

func _get_random_grass_position() -> Vector2:
	if _tile_map_layer == null:
		# Если слой не найден, возвращаем случайную позицию (для отладки)
		return Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000))
	
	var tile_set = _tile_map_layer.tile_set
	if tile_set == null:
		return Vector2.ZERO
	
	# Получаем все используемые клетки на слое Grass
	var used_rect = _tile_map_layer.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Vector2.ZERO
	
	# Пробуем найти случайную клетку с травой (несколько попыток)
	var max_attempts = 50
	for i in range(max_attempts):
		var random_x = randi_range(used_rect.position.x, used_rect.end.x - 1)
		var random_y = randi_range(used_rect.position.y, used_rect.end.y - 1)
		
		# Проверяем, является ли эта клетка травой
		var tile_data = _tile_map_layer.get_cell_tile_data(Vector2i(random_x, random_y))
		if tile_data:
			# Проверяем terrain
			var terrain_type = tile_data.get_terrain_type(_grass_terrain_set, 0)
			if terrain_type == _grass_terrain:
				# Преобразуем координаты клетки в мировые координаты
				var world_position = _tile_map_layer.to_global(
					_tile_map_layer.map_to_local(Vector2i(random_x, random_y)) + Vector2(0.5, 0.5)
				)
				return world_position
	
	return Vector2.ZERO

func _spawn_enemy(position: Vector2) -> void:
	if enemy_scene == null:
		push_error("Enemy scene не назначена в инспекторе!")
		return
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	get_parent().add_child(enemy)
