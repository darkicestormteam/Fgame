extends CharacterBody2D

const SPEED = 300.0

# Сохраняем ссылку на игрока при запуске
var _player: Node2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Ищем игрока один раз при старте
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		print("Предупреждение: Игрок не найден в группе 'player'. Враг не будет двигаться.")
	
	# Убедимся, что анимация играет
	if animated_sprite:
		animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if _player == null:
		# Если игрок не был найден или был удален, не обновляем позицию
		velocity = Vector2.ZERO
		animated_sprite.animation = "idle"
		move_and_slide()
		return

	# Вычисляем направление к игроку
	var direction: Vector2 = (_player.global_position - global_position).normalized()
	
	# Двигаемся к игроку всегда, если он существует
	velocity = direction * SPEED
	
	# Поворачиваем спрайт в сторону игрока через flip_h
	if direction.x < 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
	# Включаем анимацию ходьбы
	animated_sprite.animation = "walk"
	
	move_and_slide()
