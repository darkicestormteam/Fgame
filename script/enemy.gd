extends CharacterBody2D

@export var speed: float = 50.0
@export var health: int = 3
@export var knockback_resistance: float = 0.0
@export var score_value: int = 10

var _player: Node2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_knockedback: bool = false
var knockback_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		print("Предупреждение: Игрок не найден в группе 'player'.")

func knockback(direction: Vector2, distance: float) -> void:
	# Учитываем сопротивление отталкиванию
	var actual_distance = distance * (1.0 - knockback_resistance)
	if actual_distance <= 0:
		return
	velocity = direction * actual_distance
	is_knockedback = true
	knockback_timer = 0.15  # Длительность отталкивания в секундах

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	# Добавляем очки игроку (если есть система очков)
	# Можно расширить позже
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

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	
	velocity = direction * speed
	
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true

	move_and_slide()

	if velocity.length_squared() > 1.0:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
