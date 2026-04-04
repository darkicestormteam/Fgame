extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_area: Area2D = $AttackArea

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
	
	# Отключаем мониторинг AttackArea по умолчанию
	attack_area.monitoring = false

func _on_attack_timer_timeout() -> void:
	# Проигрываем анимацию атаки только если не атакуем сейчас
	if not is_attacking:
		is_attacking = true
		animated_sprite.play("attack")
		# Включаем мониторинг AttackArea во время атаки
		attack_area.monitoring = true

func _on_animation_finished() -> void:
	# Сбрасываем флаг атаки когда анимация закончилась
	if animated_sprite.animation == "attack":
		is_attacking = false
		# Отключаем мониторинг AttackArea после завершения атаки
		attack_area.monitoring = false

func _physics_process(delta: float) -> void:
	# Используем ваши кастомные имена действий
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = input_direction * SPEED

	if velocity.length_squared() > 0:
		# Поворот спрайта
		if velocity.x > 0:
			animated_sprite.flip_h = false
			attack_area.rotation = 0
		elif velocity.x < 0:
			animated_sprite.flip_h = true
			attack_area.rotation = deg_to_rad(180)
		
		# Анимация ходьбы (не прерываем атаку)
		if not is_attacking and animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		# Анимация покоя (не прерываем атаку)
		if not is_attacking and animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	move_and_slide()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		body.queue_free()
