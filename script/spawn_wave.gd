
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

# enemy_spawner.gd
extends Node2D

@export var waves: Array[SpawnWave] = [] # Сюда в инспекторе накидаешь созданные ресурсы волн
@export var player: Node2D # Ссылка на игрока, если нужно спавнить вокруг него

var _timers: Array = [] # Храним таймеры для активных волн

func _ready():
	# Инициализируем таймеры для каждой волны
	for wave in waves:
		var timer = Timer.new()
		timer.wait_time = wave.spawn_interval
		timer.timeout.connect(_on_spawn_timer_timeout.bind(wave))
		add_child(timer)
		
		# Запускаем таймер старта волны
		var start_timer = get_tree().create_timer(wave.start_time)
		start_timer.timeout.connect(_start_wave.bind(timer, wave))
		
		_timers.append({
			"timer": timer,
			"wave": wave,
			"count": 0
		})

func _start_wave(timer: Timer, wave: SpawnWave):
	print("Началась волна: ", wave.enemy_scene.resource_path)
	timer.start()
	# Если нужно спавнить сразу первого врага при старте волны, можно вызвать _on_spawn_timer_timeout вручную

func _on_spawn_timer_timeout(wave: SpawnWave):
	# Находим данные о текущей волне
	var wave_data = _timers.find(func(d): return d.wave == wave)
	if wave_data == null: return
	
	# Проверка лимита количества
	if wave.max_count > 0 and wave_data.count >= wave.max_count:
		wave_data.timer.stop()
		return

	# Логика спавна
	var enemy = wave.enemy_scene.instantiate()
	
	# Позиция спавна (случайная точка за пределами экрана или вокруг игрока)
	# Пример: спавн слева за экраном
	var spawn_pos = Vector2(-100, randf_range(0, 600)) 
	if player:
		# Можно спавнить случайно вокруг игрока
		spawn_pos = player.global_position + Vector2(randf_range(-400, 400), randf_range(-400, 400))
	
	enemy.global_position = spawn_pos
	get_parent().add_child(enemy) # Добавляем врага в общую сцену
	
	wave_data.count += 1

