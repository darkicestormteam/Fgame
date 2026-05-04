@tool
class_name WaveConfig
extends Resource

@export_group("Настройки волны")
@export var spawn_time: float = 0.0: set = set_spawn_time
@export var enemy_scene: PackedScene: set = set_enemy_scene
@export var spawn_count: int = 1: set = set_spawn_count
@export var spawn_interval: float = 1.0: set = set_spawn_interval

func set_spawn_time(value: float) -> void:
	spawn_time = max(0.0, value)

func set_enemy_scene(value: PackedScene) -> void:
	enemy_scene = value

func set_spawn_count(value: int) -> void:
	spawn_count = max(1, value)

func set_spawn_interval(value: float) -> void:
	spawn_interval = max(0.1, value)
