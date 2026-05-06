extends Node2D


@onready var animation_player: AnimationPlayer = $AnimationPlayer(gnom)

var _is_paused: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Скрываем preview изначально
	visible = false
	# Устанавливаем процесс внутри паузы чтобы анимация играла даже когда игра на паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	animation_player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Подключаемся к сигналу первой волны от EnemySpawner
	var enemy_spawner = get_node_or_null("../EnemySpawner")
	if enemy_spawner:
		enemy_spawner.first_wave_started.connect(_on_first_wave_started)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_first_wave_started() -> void:
	# Ставим игру на паузу
	get_tree().paused = true
	# Запускаем анимацию preview
	play_preview()
	# Ждем окончания анимации и скрываем preview
	await animation_player.animation_finished
	hide_preview()
	# Снимаем игру с паузы
	get_tree().paused = false


func play_preview() -> void:
	visible = true
	animation_player.play("Gnom")


func hide_preview() -> void:
	visible = false
	animation_player.play("RESET")
