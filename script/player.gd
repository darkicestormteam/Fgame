extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var attack_area: Area2D = $AttackArea
@onready var sword_whoosh: AudioStreamPlayer2D = $"Sword Whoosh"
@onready var footstep: AudioStreamPlayer2D = $Footstep
@onready var invincibility_timer: Timer = $InvincibilityTimer

var is_attacking: bool = false
var enemies_in_area: Array = []
var last_footstep_time: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.4

# Система жизней
var max_lives: int = 3
var current_lives: int = 3
var is_invincible: bool = false
var blink_visible: bool = true
var hp_bar_node: Node = null

func _ready() -> void:
	# Создаем таймер для атаки
	attack_timer = Timer.new()
	attack_timer.wait_time = 2.0
	attack_timer.autostart = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	# Подключаемся к окончанию анимации
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Подключаемся к изменению кадра анимации
	animated_sprite.frame_changed.connect(_on_frame_changed)
	
	# Отключаем мониторинг AttackArea по умолчанию
	attack_area.monitoring = false
	
	# Запускаем процесс мигания
	set_process(true)
	
	# Находим HP_bar и сохраняем ссылку
	await get_tree().process_frame
	hp_bar_node = get_tree().get_first_node_in_group("hp_bar")

func _process(delta: float) -> void:
	# Мигание во время неуязвимости (каждые 0.1 секунды)
	if is_invincible:
		var current_time = Time.get_ticks_msec() / 1000.0
		# Меняем видимость каждые 0.1 секунды
		if fmod(current_time, 0.2) < 0.1:
			animated_sprite.visible = true
		else:
			animated_sprite.visible = false
	else:
		animated_sprite.visible = true

func _on_invincibility_timer_timeout() -> void:
	is_invincible = false
	animated_sprite.visible = true
	# Включаем коллизию обратно
	collision_layer = 2

func take_damage() -> void:
	if is_invincible:
		return
	
	current_lives -= 1
	
	# Обновляем HP бар
	if hp_bar_node and hp_bar_node.has_method("update_hearts"):
		hp_bar_node.update_hearts(current_lives)
	
	if current_lives <= 0:
		# Игра окончена
		get_tree().paused = true
		var game_over = get_tree().get_first_node_in_group("game_over")
		if not game_over:
			game_over = get_node("/root/GameOver")
		if not game_over:
			game_over = get_tree().current_scene.get_node_or_null("GameOver")
		
		if game_over:
			game_over.visible = true
	else:
		# Активируем неуязвимость
		is_invincible = true
		invincibility_timer.start()
		# Отключаем коллизию чтобы враги проходили сквозь
		collision_layer = 0

# Функция для добавления жизней (для бафов)
func add_life(amount: int = 1) -> void:
	max_lives += amount
	current_lives = min(current_lives + amount, max_lives)

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
		# Очищаем список врагов
		enemies_in_area.clear()

func _on_frame_changed() -> void:
	# Проверяем, что это анимация атаки и 4-й кадр (индекс 3)
	if animated_sprite.animation == "attack" and animated_sprite.frame == 3:
		# Воспроизводим звук Sword Whoosh
		sword_whoosh.pitch_scale = randf_range(0.9, 1.2)
		sword_whoosh.play()
		# Наносим урон всем врагам в зоне
		for enemy in enemies_in_area:
			if is_instance_valid(enemy):
				enemy.queue_free()
		# Очищаем список после нанесения урона
		enemies_in_area.clear()

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
		
		# Воспроизведение звука шагов с изменением высоты тона
		if not is_attacking and Time.get_ticks_msec() / 1000.0 - last_footstep_time >= FOOTSTEP_INTERVAL:
			last_footstep_time = Time.get_ticks_msec() / 1000.0
			footstep.pitch_scale = randf_range(0.8, 1.2)
			footstep.play()
	else:
		# Анимация покоя (не прерываем атаку)
		if not is_attacking and animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	move_and_slide()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		# Добавляем врага в список, но не уничтожаем сразу
		if body not in enemies_in_area:
			enemies_in_area.append(body)

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body in enemies_in_area:
		enemies_in_area.erase(body)
