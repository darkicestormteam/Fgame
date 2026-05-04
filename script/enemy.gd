extends CharacterBody2D

@export var speed: float = 50.0
@export var health: int = 1

var _player: Node2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_knockedback: bool = false
var knockback_timer: float = 0.0

func _ready() -> void:
	# Исправлено: "Enemy" с большой буквы, чтобы совпадать с проверкой в player.gd
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		print("Предупреждение: Игрок не найден в группе 'player'.")

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
