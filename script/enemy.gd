extends CharacterBody2D

@export var speed: float = 50.0
@export var health: int = 1
@export var attack_distance: float = 50.0
@export var attack_collision_start_frame: int = 3
@export var attack_collision_end_frame: int = 6

var _player: Node2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Attack
@onready var attack_sound: AudioStreamPlayer2D = $Attackweapon
var is_knockedback: bool = false
var knockback_timer: float = 0.0
var is_attacking: bool = false
var last_pitch: float = 1.0
var is_flashing: bool = false
var flash_timer: float = 0.0
var flash_duration: float = 0.5
var flash_interval: float = 0.1
var original_modulate: Color = Color.WHITE

func _ready() -> void:
	add_to_group("Enemy")
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		print("Предупреждение: Игрок не найден в группе 'player'.")
	
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	attack_area.monitoring = false
	original_modulate = animated_sprite.modulate

func knockback(direction: Vector2, distance: float) -> void:
	velocity = direction * distance
	is_knockedback = true
	knockback_timer = 0.15

func take_damage(amount: int) -> void:
	health -= amount
	if not is_flashing:
		is_flashing = true
		flash_timer = flash_duration
	if health <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	# Обработка мигания при получении урона
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0.0:
			is_flashing = false
			animated_sprite.modulate = original_modulate
		else:
			var flash_state = int(flash_timer / flash_interval) % 2
			if flash_state == 0:
				animated_sprite.modulate = Color.RED
			else:
				animated_sprite.modulate = original_modulate
	
	if is_knockedback:
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			is_knockedback = false
		move_and_slide()
		return
	
	if _player == null:
		velocity = Vector2.ZERO
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
		return
	
	var distance_to_player: float = global_position.distance_to(_player.global_position)
	
	# Проверяем дистанцию до игрока
	if distance_to_player <= attack_distance:
		if not is_attacking:
			is_attacking = true
			animated_sprite.play("attack")
		velocity = Vector2.ZERO
		return
	
	# Логика движения
	if not is_attacking:
		var direction: Vector2 = (_player.global_position - global_position).normalized()
		
		# Запоминаем желаемое направление для анимации и логики
		var desired_velocity = direction * speed
		
		if desired_velocity.x > 0:
			animated_sprite.flip_h = false
			attack_area.scale.x = abs(attack_area.scale.x)
		elif desired_velocity.x < 0:
			animated_sprite.flip_h = true
			attack_area.scale.x = -abs(attack_area.scale.x)
		
		velocity = desired_velocity
		
		# Первый проход физики
		move_and_slide()
		
		# --- УЛУЧШЕННАЯ ЛОГИКА СКОЛЬЖЕНИЯ ---
		# Если произошло столкновение
		if get_slide_collision_count() > 0:
			var collision = get_slide_collision(0)
			var normal = collision.get_normal()
			
			# Получаем оставшуюся скорость после удара о стену (она обычно гасится движком)
			# Но мы хотим заставить врага скользить вдоль стены активно
			var tangent = -normal.orthogonal() # Вектор вдоль стены
			
			# Определяем, в какую сторону вдоль стены выгоднее идти (к игроку)
			var to_player = (_player.global_position - global_position).normalized()
			
			# Если касательная направлена от игрока, разворачиваем её
			if tangent.dot(to_player) < 0:
				tangent = -tangent
			
			# ХИТРОСТЬ: Мы смешиваем исходное желание идти к игроку и скольжение.
			# Это предотвращает "прилипание", так как мы не ждем полной остановки.
			# Проекция желаемой скорости на касательную
			var slide_speed = desired_velocity.dot(tangent)
			
			# Если проекция положительная (мы хотим двигаться вдоль стены к игроку)
			if slide_speed > 0:
				# Принудительно задаем скорость скольжения. 
				# Умножаем на 1.05, чтобы быть чуть быстрее обычного трения, пробивая застревание
				velocity = tangent * slide_speed * 1.05
				
				# Второй проход физики для применения нового вектора сразу же
				move_and_slide()

	# Анимация
	if not is_attacking:
		if velocity.length_squared() > 1.0:
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack":
		var current_frame = animated_sprite.frame
		if current_frame == attack_collision_start_frame:
			attack_area.monitoring = true
			if attack_sound and not attack_sound.playing:
				last_pitch = randf_range(0.9, 1.2)
				attack_sound.pitch_scale = last_pitch
				attack_sound.play()
		elif current_frame >= attack_collision_end_frame:
			attack_area.monitoring = false
			is_attacking = false

func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage()

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
