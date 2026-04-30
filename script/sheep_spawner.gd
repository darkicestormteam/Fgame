extends Node2D

@export var sheep_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var player_node: NodePath

var _player: Node2D = null
var _spawn_timer: float = 0.0
var _is_enabled: bool = false  # Флаг активности спавнера

func _ready() -> void:
	# Если sheep_scene не назначен, загружаем его автоматически
	if sheep_scene == null:
		sheep_scene = load("res://scenes/sheep.tscn")
	
	# Ждем пока игрок будет готов
	await get_tree().process_frame
	if has_node(player_node):
		_player = get_node(player_node)
	else:
		_player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	# Спавним овец только если способность разблокирована
	if not _is_enabled or _player == null:
		return

	_spawn_timer += delta

	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_spawn_sheep()

func _spawn_sheep() -> void:
	if sheep_scene == null or _player == null:
		print("[SheepSpawner] Cannot spawn: sheep_scene=", sheep_scene != null, " player=", _player != null)
		return

	# Создаем овцу в случайной позиции около игрока
	var sheep = sheep_scene.instantiate()

	# Спавним овцу в случайном направлении от игрока на расстоянии 30-50 пикселей
	var angle = randf() * TAU
	var distance = randf_range(30.0, 50.0)
	var spawn_position = _player.global_position + Vector2(cos(angle), sin(angle)) * distance

	sheep.global_position = spawn_position
	get_parent().add_child(sheep)

# Метод для разблокировки способности (вызывается из spellmenu)
func enable_sheep_spell() -> void:
	_is_enabled = true
	print("[SheepSpawner] Sheep spell enabled!")
