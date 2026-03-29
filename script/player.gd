extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	# Создаем таймер для атаки
	attack_timer = Timer.new()
	attack_timer.wait_time = 2.0
	attack_timer.autostart = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

func _on_attack_timer_timeout() -> void:
	# Проигрываем анимацию атаки
	animated_sprite.play("attack")

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
		
		# Анимация ходьбы (не прерываем атаку)
		if animated_sprite.animation != "walk" and animated_sprite.animation != "attack":
			animated_sprite.play("walk")
	else:
		# Анимация покоя (не прерываем атаку)
		if animated_sprite.animation != "idle" and animated_sprite.animation != "attack":
			animated_sprite.play("idle")

	move_and_slide()
