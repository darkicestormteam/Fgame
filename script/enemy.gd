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

func _ready() -> void:
	# Добавляем в группу "Enemy" с большой буквы, чтобы совпадать с проверкой в player.gd и сценой
	add_to_group("Enemy")
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		print("Предупреждение: Игрок не найден в группе 'player'.")
	
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	attack_area.monitoring = false

func knockback(direction: Vector2, distance: float) -> void:
	velocity = direction * distance
	is_knockedback = true
	knockback_timer = 0.15  # Длительность отталкивания в секундах

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
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
		# Если еще не атакуем, начинаем атаку
		if not is_attacking:
			is_attacking = true
			animated_sprite.play("attack")
		# Останавливаем движение во время атаки
		velocity = Vector2.ZERO
		# Не меняем направление спрайта во время атаки
		return
	
	# Если игрок вне зоны атаки и мы не в процессе атаки, продолжаем движение
	if not is_attacking:
		var direction: Vector2 = (_player.global_position - global_position).normalized()
		
		velocity = direction * speed
		
		if velocity.x > 0:
			animated_sprite.flip_h = false
			attack_area.scale.x = abs(attack_area.scale.x)
		elif velocity.x < 0:
			animated_sprite.flip_h = true
			attack_area.scale.x = -abs(attack_area.scale.x)
	
	move_and_slide()
	
	if not is_attacking and velocity.length_squared() > 1.0:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	elif not is_attacking:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack":
		var current_frame = animated_sprite.frame
		# Включаем коллизию на указанном кадре (настраивается в инспекторе)
		if current_frame == attack_collision_start_frame:
			attack_area.monitoring = true
			# Воспроизводим звук атаки с разной тональностью
			if attack_sound and not attack_sound.playing:
				last_pitch = randf_range(0.9, 1.2)
				attack_sound.pitch_scale = last_pitch
				attack_sound.play()
		# Выключаем коллизию после указанного кадра (настраивается в инспекторе)
		elif current_frame >= attack_collision_end_frame:
			attack_area.monitoring = false
			is_attacking = false

func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Вызываем метод получения урона у игрока
		body.take_damage()

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
