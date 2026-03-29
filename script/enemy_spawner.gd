extends Node2D

@export var enemy_scene: PackedScene
@export var max_enemies: int = 30
@export var spawn_interval: float = 0.5

var _spawn_timer: Timer
var _viewport_size: Vector2

func _ready() -> void:
	_viewport_size = get_viewport_rect().size
	
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)
	_spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	var current_enemies = get_tree().get_nodes_in_group("enemy")
	
	if current_enemies.size() >= max_enemies:
		return
	
	if enemy_scene == null:
		print("Ошибка: enemy_scene не назначен в инспекторе!")
		return
	
	var enemy = enemy_scene.instantiate()
	
	var spawn_position = Vector2(
		randf_range(0, _viewport_size.x),
		randf_range(0, _viewport_size.y)
	)
	
	enemy.global_position = spawn_position
	add_child(enemy)