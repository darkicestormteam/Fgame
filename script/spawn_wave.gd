class_name SpawnWave
extends Resource

@export var enemy_scene: PackedScene
@export var start_time: float = 0.0  # Время начала спавна этой волны (в секундах)
@export var spawn_interval: float = 1.0  # Интервал между спавном врагов в этой волне
@export var max_enemies: int = 5  # Максимальное количество врагов этой волны на сцене
@export var total_to_spawn: int = 10  # Общее количество врагов, которое нужно заспавнить за волну

var _spawned_count: int = 0
var _spawn_timer: float = 0.0
var _is_active: bool = false

func reset():
	_spawned_count = 0
	_spawn_timer = 0.0
	_is_active = false

func is_wave_finished() -> bool:
	return _spawned_count >= total_to_spawn
