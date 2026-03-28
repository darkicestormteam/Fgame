extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Используем ваши кастомные имена действий
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = input_direction * SPEED

	if velocity.length_squared() > 0:
		# Поворот спрайта
		if velocity.x > 0:
			animated_sprite.flip_h = false
		elif velocity.x < 0:
			animated_sprite.flip_h = true
		
		# Анимация ходьбы
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		# Анимация покоя
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	move_and_slide()
