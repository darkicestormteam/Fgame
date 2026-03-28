extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Находим игрока по тегу или имени
	var player = get_tree().get_first_node_in_group("player")
	
	if not player:
		# Если игрок не найден, останавливаемся
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		move_and_slide()
		return
	
	# Вычисляем направление к игроку
	var direction = (player.global_position - global_position).normalized()
	
	if direction.length() > 0.01:
		velocity = direction * SPEED
		
		# Поворачиваем спрайт в сторону игрока через flip_h
		if direction.x < 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
