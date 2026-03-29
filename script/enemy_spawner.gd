extends Node2D

@export var enemy_scene: PackedScene
@export var max_enemies: int = 30
@export var spawn_interval: float = 0.5
@export var grass_layer: TileMapLayer

var _spawn_timer: Timer
var _valid_spawn_positions: Array[Vector2] = []

func _ready() -> void:
	if grass_layer == null:
		print("Ошибка: не назначен слой Grass в инспекторе!")
		return
	
	_find_valid_spawn_positions()
	
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_spawn_timer.start()

func _find_valid_spawn_positions() -> void:
	_valid_spawn_positions.clear()
	var used_cells = grass_layer.get_used_cells()
	for cell in used_cells:
		var world_pos = grass_layer.map_to_local(cell)
		_valid_spawn_positions.append(world_pos)
	
	if _valid_spawn_positions.is_empty():
		print("Предупреждение: слой Grass не содержит тайлов!")

func _on_spawn_timer_timeout() -> void:
	var current_enemies = get_tree().get_nodes_in_group("enemy")
	
	if current_enemies.size() >= max_enemies:
		return
	
	if enemy_scene == null:
		print("Ошибка: enemy_scene не назначен в инспекторе!")
		return
	
	if _valid_spawn_positions.is_empty():
		print("Ошибка: нет доступных позиций для спавна на слое Grass!")
		return
	
	var enemy = enemy_scene.instantiate()
	
	var random_index = randi() % _valid_spawn_positions.size()
	var spawn_position = _valid_spawn_positions[random_index]
	
	# Конвертируем локальную позицию слоя в глобальную
	var global_spawn_position = grass_layer.to_global(spawn_position)
	
	enemy.global_position = global_spawn_position
	get_parent().add_child(enemy)
