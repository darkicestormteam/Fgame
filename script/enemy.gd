extends CharacterBody2D

const SPEED = 50.0

var _player: Node2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Переменные для отталкивания
var is_pushed: bool = false
var push_velocity: Vector2 = Vector2.ZERO
var push_distance: float = 0.0
var push_remaining: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		print("Предупреждение: Игрок не найден в группе 'player'.")

func push_back(direction: Vector2, distance: float) -> void:
	is_pushed = true
	push_velocity = direction.normalized()
	push_remaining = distance

func _physics_process(delta: float) -> void:
	if is_pushed and push_remaining > 0:
		var move_step = min(push_remaining, 400 * delta)
		global_position += push_velocity * move_step
		push_remaining -= move_step
		
		if push_remaining <= 0:
			is_pushed = false
		
		return
	
	if _player == null:
		velocity = Vector2.ZERO
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	
	velocity = direction * SPEED
	
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
