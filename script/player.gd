extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer

var is_attacking: bool = false

func _ready() -> void:
	# Создаем таймер для атаки
	attack_timer = Timer.new()
	attack_timer.wait_time = 2.0
	attack_timer.autostart = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	# Подключаемся к окончанию анимации
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_attack_timer_timeout() -> void:
	# Проигрываем анимацию атаки только если не атакуем сейчас
	if not is_attacking:
		is_attacking = true
		animated_sprite.play("attack")

func _on_animation_finished() -> void:
	# Сбрасываем флаг атаки когда анимация закончилась
	if animated_sprite.animation == "attack":
		is_attacking = false

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
		if not is_attacking and animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		# Анимация покоя (не прерываем атаку)
		if not is_attacking and animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	move_and_slide()


func _on_attack_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
