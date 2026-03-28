extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Получаем направление ввода (WASD или стрелки)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * SPEED
		
		# Поворачиваем спрайт в зависимости от направления движения по оси X
		if direction.x < 0:
			animated_sprite.flip_h = true
		elif direction.x > 0:
			animated_sprite.flip_h = false
		
		# Включаем анимацию ходьбы
		animated_sprite.animation = "walk"
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		# Включаем анимацию покоя
		animated_sprite.animation = "idle"
	
	move_and_slide()
